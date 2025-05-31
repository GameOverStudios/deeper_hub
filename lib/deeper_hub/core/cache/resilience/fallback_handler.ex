defmodule DeeperHub.Core.Cache.Resilience.FallbackHandler do
  @moduledoc """
  Mecanismo de fallback para o sistema de cache.

  Este módulo implementa estratégias de fallback para garantir que
  o sistema continue funcionando mesmo quando o cache apresentar
  falhas ou indisponibilidade. As estratégias incluem:

  1. Stale - Permite o uso de dados expirados quando o cache falhar
  2. Local - Armazena cópias locais de dados frequentemente acessados
  3. Degraded - Opera em modo de funcionalidade reduzida
  """

  require DeeperHub.Core.Logger

  @doc """
  Executa uma operação de cache com fallback.

  ## Parâmetros

    * `cache_name` - Nome do cache
    * `key` - Chave do cache
    * `fallback_fn` - Função para gerar o valor quando cache falha
    * `opts` - Opções de configuração
      * `:strategy` - Estratégia de fallback (:stale, :local, :degraded)
      * `:ttl` - Tempo de vida para itens no cache em ms
      * `:stale_ttl` - Tempo adicional para considerar dados "stale" em ms

  ## Retorno

    * `{:ok, value}` - Valor recuperado do cache ou fallback
    * `{:error, reason}` - Erro não tratável

  ## Exemplos

      iex> FallbackHandler.with_fallback(:my_cache, "user:123", fn ->
             fetch_user_from_database(123)
           end)
      {:ok, %User{id: 123, name: "João"}}
  """
  @spec with_fallback(atom(), term(), (-> {:ok, term()} | {:error, term()}), keyword()) ::
          {:ok, term()} | {:error, term()}
  def with_fallback(cache_name, key, fallback_fn, opts \\ []) do
    strategy = Keyword.get(opts, :strategy, :stale)

    # Tenta obter do cache primeiro
    case Cachex.get(cache_name, key) do
      {:ok, nil} ->
        # Cache miss - Executa fallback e armazena
        execute_fallback(cache_name, key, fallback_fn, opts)

      {:ok, value} ->
        # Cache hit
        {:ok, value}

      {:error, reason} ->
        # Falha no cache - Aplica estratégia de fallback
        DeeperHub.Core.Logger.warning("Falha no cache #{inspect(cache_name)}, usando fallback (#{inspect(strategy)}): #{inspect(reason)}")

        handle_cache_failure(cache_name, key, fallback_fn, strategy, opts)
    end
  end

  @doc """
  Invalida um item no cache, garantindo que os backups também sejam atualizados.

  ## Parâmetros

    * `cache_name` - Nome do cache
    * `key` - Chave do cache
    * `opts` - Opções adicionais

  ## Retorno

    * `:ok` - Item invalidado
    * `{:error, reason}` - Erro ao invalidar
  """
  @spec invalidate(atom(), term(), keyword()) :: :ok | {:error, term()}
  def invalidate(cache_name, key, _opts \\ []) do
    # Invalida no cache principal
    case Cachex.del(cache_name, key) do
      {:ok, _} ->
        # Tenta invalidar também no cache local de fallback se existir
        invalidate_local_backup(key)
        :ok

      {:error, reason} ->
        DeeperHub.Core.Logger.warning("Erro ao invalidar cache para #{inspect(key)}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Funções privadas

  # Executa a função de fallback, armazena no cache e retorna o valor
  defp execute_fallback(cache_name, key, fallback_fn, opts) do
    ttl = Keyword.get(opts, :ttl, 300_000) # 5 minutos padrão

    case fallback_fn.() do
      {:ok, value} ->
        # Armazena no cache com TTL configurado
        Cachex.put(cache_name, key, value, ttl: ttl)

        # Armazena cópia local para fallback se estratégia for :local
        if Keyword.get(opts, :strategy) == :local do
          store_local_backup(key, value, ttl)
        end

        {:ok, value}

      {:error, reason} = error ->
        DeeperHub.Core.Logger.error("Erro na função de fallback para #{inspect(key)}: #{inspect(reason)}")
        error
    end
  end

  # Lida com falhas no cache usando diferentes estratégias
  defp handle_cache_failure(cache_name, key, fallback_fn, :stale, opts) do
    # Estratégia STALE: tenta obter dados expirados
    stale_ttl = Keyword.get(opts, :stale_ttl, 86_400_000) # 24 horas padrão

    case Cachex.get(cache_name, key, [return: :full]) do
      {:ok, {_key, value, touched, ttl}} ->
        # Verifica se o item está expirado mas ainda dentro do ttl "stale"
        now = :os.system_time(:millisecond)
        expiry = touched + ttl
        stale_expiry = expiry + stale_ttl

        cond do
          now <= expiry ->
            # Item ainda é válido
            {:ok, value}

          now <= stale_expiry ->
            # Item está "stale" mas utilizável
            DeeperHub.Core.Logger.info("Usando dados 'stale' para #{inspect(key)} durante falha do cache")
            {:ok, value}

          true ->
            # Item muito antigo - tenta executar fallback
            execute_fallback(cache_name, key, fallback_fn, opts)
        end

      _ ->
        # Não há dados no cache, nem mesmo expirados
        execute_fallback(cache_name, key, fallback_fn, opts)
    end
  end

  defp handle_cache_failure(_cache_name, key, fallback_fn, :local, opts) do
    # Estratégia LOCAL: verifica cache local
    case get_local_backup(key) do
      {:ok, value} ->
        DeeperHub.Core.Logger.info("Usando backup local para #{inspect(key)} durante falha do cache")
        {:ok, value}

      {:error, _reason} ->
        # Não há backup local, tenta executar fallback
        execute_fallback(:local_backup_cache, key, fallback_fn, opts)
    end
  end

  defp handle_cache_failure(_cache_name, _key, _fallback_fn, :degraded, _opts) do
    # Estratégia DEGRADED: retorna erro com status de degradação
    {:error, :service_degraded}
  end

  # Gerenciamento de backups locais

  defp store_local_backup(key, value, ttl) do
    # Usa ETS para armazenar backups locais
    table = get_or_create_local_table()
    expiry = :os.system_time(:millisecond) + ttl
    :ets.insert(table, {key, value, expiry})
    :ok
  end

  defp get_local_backup(key) do
    table = get_or_create_local_table()
    now = :os.system_time(:millisecond)

    case :ets.lookup(table, key) do
      [{^key, value, expiry}] when expiry > now ->
        {:ok, value}

      [{^key, _value, _expiry}] ->
        # Item expirado
        :ets.delete(table, key)
        {:error, :expired}

      [] ->
        {:error, :not_found}
    end
  end

  defp invalidate_local_backup(key) do
    table = get_or_create_local_table()
    :ets.delete(table, key)
    :ok
  end

  defp get_or_create_local_table do
    table_name = :deeper_hub_local_cache_backup

    case :ets.whereis(table_name) do
      :undefined ->
        :ets.new(table_name, [:named_table, :set, :public,
                             write_concurrency: true,
                             read_concurrency: true])

      table ->
        table
    end
  end
end
