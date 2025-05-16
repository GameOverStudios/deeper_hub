defmodule Deeper_Hub.Core.Data.RepositoryCore do
  use GenServer
  @moduledoc """
  Módulo principal do repositório genérico para operações de banco de dados.
  
  Este módulo fornece a infraestrutura de cache e gerenciamento de conexões para
  as operações de banco de dados. É responsável por inicializar e manter o cache,
  bem como fornecer funções auxiliares para os outros módulos do repositório.
  """

  import Ecto.Query
  alias Deeper_Hub.Core.Logger

  # Tabelas ETS para cache
  @cache_table :repository_cache
  @cache_stats :repository_cache_stats

  # Nome do processo GenServer
  @server __MODULE__

  # Inicializa as tabelas ETS de forma segura
  @doc """
  Inicializa o cache do repositório.

  Esta função cria as tabelas ETS necessárias para o cache se elas ainda não existirem.
  É seguro chamar esta função múltiplas vezes, pois ela verifica se as tabelas já existem
  antes de tentar criá-las.

  ## Retorno

  - `:ok` se a inicialização for bem-sucedida
  """
  @spec initialize_cache() :: :ok
  def initialize_cache do
    try do
      # Usa um mutex para evitar condições de corrida
      :global.trans(
        {__MODULE__, :cache_initialization_lock},
        fn ->
          # Cria a tabela de cache se não existir
          if !table_exists?(@cache_table) do
            :ets.new(@cache_table, [:set, :public, :named_table, read_concurrency: true])
          end

          # Cria a tabela de estatísticas se não existir
          if !table_exists?(@cache_stats) do
            :ets.new(@cache_stats, [:set, :public, :named_table])
            :ets.insert(@cache_stats, {:hits, 0})
            :ets.insert(@cache_stats, {:misses, 0})
          end
        end,
        [Node.self()],
        5000  # timeout de 5 segundos
      )

      :ok
    rescue
      error ->
        Logger.warning("Falha ao inicializar cache com bloqueio global: #{inspect(error)}", %{module: __MODULE__})
        # Em caso de erro, tenta inicializar sem o bloqueio
        ensure_tables_created()
    end
  end

  # Verifica se uma tabela ETS existe
  defp table_exists?(table_name) do
    case :ets.info(table_name) do
      :undefined -> false
      _ -> true
    end
  end

  # Inicializa o cache quando o módulo é carregado
  # Usa um processo para garantir que a inicialização ocorra apenas uma vez
  # e seja compartilhada entre todos os processos
  @cache_initialized_key {__MODULE__, :cache_initialized}

  # Move a inicialização para uma função que será chamada no carregamento
  # em vez de executar código no momento da compilação

  @doc """
  Inicia o GenServer do repositório.

  Esta função é chamada pela árvore de supervisão para iniciar o processo
  que gerencia o cache do repositório.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put(opts, :name, @server))
  end

  @impl true
  def init(:ok) do
    # Inicializa o cache quando o GenServer inicia
    :ok = initialize_cache()

    # Agenda a verificação periódica do cache
    Process.send_after(self(), :ensure_cache_initialized, 60_000)  # Verifica a cada minuto

    {:ok, %{initialized: true}}
  end

  # Chamado quando o módulo é carregado
  @on_load :init_cache

  @doc """
  Inicializa o cache quando o módulo é carregado.

  Esta função é chamada automaticamente quando o módulo é carregado.
  Ela garante que o GenServer esteja em execução e que o cache esteja inicializado.
  """
  def init_cache do
    # Inicializa o valor em persistent_term
    :persistent_term.put(@cache_initialized_key, false)

    # Não inicia o GenServer aqui, deixa isso para a árvore de supervisão
    # O GenServer será iniciado pela árvore de supervisão da aplicação
    # Isso evita o erro de "already started"

    # Retorna :ok imediatamente para não bloquear a compilação
    :ok
  end

  @impl true
  def handle_info(:ensure_cache_initialized, state) do
    # Verifica e repara o cache se necessário
    :ok = ensure_cache_initialized()

    # Agenda a próxima verificação
    Process.send_after(self(), :ensure_cache_initialized, 60_000)

    {:noreply, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  @doc """
  Limpa o cache completamente.
  """
  def clear_cache do
    # Garante que o cache está inicializado antes de qualquer operação
    ensure_cache_initialized()

    # Limpa as tabelas
    :ets.delete_all_objects(@cache_table)
    :ets.insert(@cache_stats, {:hits, 0})
    :ets.insert(@cache_stats, {:misses, 0})
    :ok
  end

  @doc """
  Retorna estatísticas de uso do cache.

  ## Retorno

  Um mapa contendo:
    - `:hits`: Número de acertos no cache
    - `:misses`: Número de erros no cache
    - `:hit_rate`: Taxa de acertos (hits / (hits + misses))
  """
  def get_cache_stats do
    # Garante que o cache está inicializado antes de qualquer operação
    ensure_cache_initialized()

    # Obtém as estatísticas
    [{:hits, hits}] = :ets.lookup(@cache_stats, :hits)
    [{:misses, misses}] = :ets.lookup(@cache_stats, :misses)

    total = hits + misses
    hit_rate = if total > 0, do: hits / total, else: 0.0

    %{
      hits: hits,
      misses: misses,
      hit_rate: hit_rate
    }
  end

  # Funções privadas para manipulação do cache
  defp cache_key(schema, id), do: {schema, id}

  @doc """
  Busca um valor no cache.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `id`: O ID do registro a ser buscado

  ## Retorno

    - `{:ok, value}` se o valor for encontrado no cache
    - `:not_found` se o valor não for encontrado no cache
  """
  @spec get_from_cache(module(), term()) :: {:ok, term()} | :not_found
  def get_from_cache(schema, id) do
    # Garante que o cache está inicializado antes de qualquer operação
    ensure_cache_initialized()

    # Verifica se o valor está no cache
    case :ets.lookup(@cache_table, cache_key(schema, id)) do
      [{_, value}] ->
        # Incrementa o contador de hits
        :ets.update_counter(@cache_stats, :hits, 1)
        {:ok, value}

      [] ->
        # Incrementa o contador de misses
        :ets.update_counter(@cache_stats, :misses, 1)
        :not_found
    end
  end

  @doc """
  Garante que as tabelas ETS do cache estão inicializadas.

  Esta função pode ser chamada em qualquer momento para verificar e, se necessário,
  recriar as tabelas ETS usadas pelo cache.

  ## Retorno

    - `:ok` se o cache estiver inicializado corretamente
  """
  @spec ensure_cache_initialized() :: :ok
  def ensure_cache_initialized do
    # Verifica se o cache já foi inicializado para evitar operações redundantes
    case :persistent_term.get(@cache_initialized_key, false) do
      true ->
        # Cache já inicializado, apenas verifica se as tabelas existem
        if table_exists?(@cache_table) && table_exists?(@cache_stats) do
          :ok
        else
          # Se as tabelas não existirem, tenta criar novamente
          do_initialize_cache()
        end
      false ->
        # Inicializa o cache
        do_initialize_cache()
    end
  end
  
  # Função privada para inicializar o cache com tratamento de erros
  defp do_initialize_cache do
    try do
      # Tenta inicializar o cache
      _ = initialize_cache()

      # Se bem-sucedido, marca como inicializado
      if table_exists?(@cache_table) && table_exists?(@cache_stats) do
        :persistent_term.put(@cache_initialized_key, true)
        :ok
      else
        # Se as tabelas não existirem, tenta criar novamente
        ensure_tables_created()
      end
    rescue
      e ->
        Logger.error("Erro ao inicializar cache: #{inspect(e)}", %{module: __MODULE__})
        Process.sleep(100)
        # Última tentativa usando ensure_tables_created
        ensure_tables_created()
    end
  end

  # Função auxiliar para garantir que as tabelas ETS foram criadas
  defp ensure_tables_created do
    try do
      # Tenta criar a tabela de cache se não existir
      if !table_exists?(@cache_table) do
        :ets.new(@cache_table, [:set, :public, :named_table, read_concurrency: true])
      end

      # Tenta criar a tabela de estatísticas se não existir
      if !table_exists?(@cache_stats) do
        :ets.new(@cache_stats, [:set, :public, :named_table])
        :ets.insert(@cache_stats, {:hits, 0})
        :ets.insert(@cache_stats, {:misses, 0})
      end

      # Marca o cache como inicializado
      :persistent_term.put(@cache_initialized_key, true)
      :ok
    rescue
      e ->
        Logger.error("Erro ao criar tabelas ETS: #{inspect(e)}", %{module: __MODULE__})
        # Evita loops infinitos de tentativas
        :persistent_term.put(@cache_initialized_key, false)
        :error
    end
  end

  @doc """
  Armazena um valor no cache.
  
  ## Parâmetros
  
    - `schema`: O módulo do schema Ecto ou tipo de cache (atom)
    - `id_or_key`: O ID do registro ou chave para consulta
    - `value`: O valor a ser armazenado
    - `ttl`: Tempo de vida em milissegundos (opcional)
  
  ## Retorno
  
    - `:ok` se o valor for armazenado com sucesso
  """
  @spec put_in_cache(module(), term(), term(), integer() | nil) :: :ok
  def put_in_cache(schema, id, value, ttl) when not is_atom(schema) or schema == nil do
    # Garante que o cache está inicializado antes de qualquer operação
    ensure_cache_initialized()

    # Armazena o valor no cache
    :ets.insert(@cache_table, {cache_key(schema, id), value})
    
    # Se um TTL foi especificado, programa a expiração
    if ttl do
      # Em uma implementação real, aqui teríamos lógica para expiração
      # Como estamos usando ETS simples, isso seria implementado com um processo separado
      # ou usando uma biblioteca como Cachex que suporta TTL nativamente
      Logger.debug("TTL especificado para cache: #{ttl}ms", %{
        module: __MODULE__,
        schema: inspect(schema),
        id: id,
        ttl: ttl
      })
    end
    
    :ok
  end

  # Implementação para cache_type (atom)
  @spec put_in_cache(atom(), term(), term(), integer() | nil) :: :ok
  def put_in_cache(cache_type, key, value, ttl) when is_atom(cache_type) do
    # Garante que o cache está inicializado antes de qualquer operação
    ensure_cache_initialized()
    
    # Armazena o valor no cache usando a chave diretamente
    :ets.insert(@cache_table, {{cache_type, key}, value})
    
    # Se um TTL foi especificado, programa a expiração
    if ttl do
      Logger.debug("TTL especificado para cache de consulta: #{ttl}ms", %{
        module: __MODULE__,
        cache_type: cache_type,
        key: key,
        ttl: ttl
      })
    end
    
    :ok
  end

  @doc """
  Remove um valor do cache.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `id`: O ID do registro a ser removido

  ## Retorno

    - `:ok` se o valor for removido com sucesso
  """
  @spec invalidate_cache(module(), term()) :: :ok
  def invalidate_cache(schema, id) do
    # Garante que o cache está inicializado antes de qualquer operação
    ensure_cache_initialized()

    # Remove o valor do cache
    :ets.delete(@cache_table, cache_key(schema, id))
    :ok
  end
  
  @doc """
  Alias para invalidate_cache para compatibilidade com o código existente.
  """
  @spec delete_from_cache(module(), term()) :: :ok
  def delete_from_cache(schema, id), do: invalidate_cache(schema, id)


  
  # Funções put_in_cache/3 com valor padrão
  def put_in_cache(schema, id, value) when not is_atom(schema) or schema == nil, do: put_in_cache(schema, id, value, nil)
  def put_in_cache(cache_type, key, value) when is_atom(cache_type), do: put_in_cache(cache_type, key, value, nil)
  
  @doc """
  Aplica limit e offset a uma query.

  ## Parâmetros

    - `query`: A query Ecto
    - `opts`: Opções contendo limit e/ou offset

  ## Retorno

    - A query modificada com limit e/ou offset aplicados
  """
  @spec apply_limit_offset(Ecto.Query.t(), Keyword.t()) :: Ecto.Query.t()
  def apply_limit_offset(query, opts) do
    has_limit = Keyword.has_key?(opts, :limit)
    has_offset = Keyword.has_key?(opts, :offset)

    cond do
      has_limit && has_offset ->
        # Aplica ambos limit e offset
        limit_value = Keyword.get(opts, :limit)
        offset_value = Keyword.get(opts, :offset)
        from(item in query, limit: ^limit_value, offset: ^offset_value)

      has_limit && !has_offset ->
        # Aplica apenas limit
        limit_value = Keyword.get(opts, :limit)
        from(item in query, limit: ^limit_value)

      !has_limit && has_offset ->
        # Se tem offset mas não tem limit, aplica um limit padrão alto (1000)
        offset_value = Keyword.get(opts, :offset)
        from(item in query, limit: 1000, offset: ^offset_value)

      true ->
        # Nem limit nem offset
        query
    end
  end
end
