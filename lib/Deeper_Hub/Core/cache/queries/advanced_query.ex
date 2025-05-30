defmodule DeeperHub.Core.Cache.Queries.AdvancedQuery do
  @moduledoc """
  Consultas avançadas para o sistema de cache do DeeperHub.

  Este módulo fornece funções para construir consultas complexas
  para o sistema de cache, permitindo filtrar entradas com base
  em diversos critérios, como padrões de chave, tempo de expiração,
  e conteúdo dos valores.
  """

  alias Cachex
  alias DeeperHub.Core.Cache.Queries.QueryBuilder

  @doc """
  Constrói uma consulta para filtrar entradas por prefixo de chave.

  ## Parâmetros

    * `prefix` - Prefixo a ser usado como filtro

  ## Retorno

    * Estrutura de consulta do Cachex

  ## Exemplos

      iex> query = DeeperHub.Core.Cache.Queries.AdvancedQuery.by_prefix("user:")
      iex> Cachex.stream(:deeper_hub_cache, query)
  """
  @spec by_prefix(binary()) :: Cachex.Query.t()
  def by_prefix(prefix) when is_binary(prefix) do
    QueryBuilder.create(
      where: fn {key, _value} ->
        is_binary(key) && String.starts_with?(key, prefix)
      end
    )
  end

  @doc """
  Constrói uma consulta para filtrar entradas por namespace.

  ## Parâmetros

    * `namespace` - Namespace a ser usado como filtro
    * `include_expired` - Se deve incluir entradas expiradas

  ## Retorno

    * Estrutura de consulta do Cachex

  ## Exemplos

      iex> query = DeeperHub.Core.Cache.Queries.AdvancedQuery.by_namespace("users")
      iex> Cachex.stream(:deeper_hub_cache, query)
  """
  @spec by_namespace(binary(), boolean()) :: Cachex.Query.t()
  def by_namespace(namespace, include_expired \\ false) when is_binary(namespace) do
    prefix = "#{namespace}:"

    # Se não deve incluir expirados, adiciona filtro de tempo
    condition = if include_expired do
      fn {key, _value} ->
        is_binary(key) && String.starts_with?(key, prefix)
      end
    else
      fn {key, value} ->
        is_binary(key) &&
        String.starts_with?(key, prefix) &&
        not is_entry_expired?(value)
      end
    end

    QueryBuilder.create(where: condition)
  end

  @doc """
  Constrói uma consulta para filtrar entradas por tempo de expiração.

  ## Parâmetros

    * `window_seconds` - Janela de tempo em segundos para expiração
    * `opts` - Opções adicionais

  ## Opções

    * `:mode` - Modo de filtro (`:expiring_soon`, `:expired`, `:not_expired`)

  ## Retorno

    * Estrutura de consulta do Cachex

  ## Exemplos

      iex> # Entradas que expiram nos próximos 60 segundos
      iex> query = DeeperHub.Core.Cache.Queries.AdvancedQuery.by_expiration(60)
      iex> Cachex.stream(:deeper_hub_cache, query)
  """
  @spec by_expiration(integer(), keyword()) :: Cachex.Query.t()
  def by_expiration(window_seconds, opts \\ []) do
    mode = Keyword.get(opts, :mode, :expiring_soon)

    condition = case mode do
      :expiring_soon ->
        # Expira em breve (dentro da janela especificada)
        fn {_key, value} ->
          case get_ttl(value) do
            nil -> false
            :infinity -> false
            ttl when is_integer(ttl) ->
              ttl > 0 && ttl <= window_seconds
          end
        end

      :expired ->
        # Já expirado
        fn {_key, value} -> is_entry_expired?(value) end

      :not_expired ->
        # Não expirado
        fn {_key, value} -> not is_entry_expired?(value) end
    end

    QueryBuilder.create(where: condition)
  end

  @doc """
  Constrói uma consulta para filtrar entradas por padrão regex na chave.

  ## Parâmetros

    * `pattern` - Padrão regex para filtrar chaves
    * `opts` - Opções adicionais

  ## Opções

    * `:include_expired` - Se deve incluir entradas expiradas (padrão: `false`)

  ## Retorno

    * Estrutura de consulta do Cachex

  ## Exemplos

      iex> regex = ~r/user:[0-9]+/
      iex> query = DeeperHub.Core.Cache.Queries.AdvancedQuery.by_regex(regex)
      iex> Cachex.stream(:deeper_hub_cache, query)
  """
  @spec by_regex(Regex.t(), keyword()) :: Cachex.Query.t()
  def by_regex(pattern, opts \\ []) when is_struct(pattern, Regex) do
    include_expired = Keyword.get(opts, :include_expired, false)

    # Se não deve incluir expirados, adiciona filtro de tempo
    condition = if include_expired do
      fn {key, _value} ->
        is_binary(key) && Regex.match?(pattern, key)
      end
    else
      fn {key, value} ->
        is_binary(key) &&
        Regex.match?(pattern, key) &&
        not is_entry_expired?(value)
      end
    end

    QueryBuilder.create(where: condition)
  end

  @doc """
  Constrói uma consulta para filtrar entradas por uma função personalizada.

  ## Parâmetros

    * `filter_fn` - Função de filtro que recebe {key, value} e retorna boolean

  ## Retorno

    * Estrutura de consulta do Cachex

  ## Exemplos

      iex> filter = fn {key, value} ->
      ...>   is_binary(key) && String.contains?(key, "admin") &&
      ...>   is_map(value) && Map.has_key?(value, :role)
      ...> end
      iex> query = DeeperHub.Core.Cache.Queries.AdvancedQuery.custom(filter)
      iex> Cachex.stream(:deeper_hub_cache, query)
  """
  @spec custom((tuple() -> boolean())) :: Cachex.Query.t()
  def custom(filter_fn) when is_function(filter_fn, 1) do
    QueryBuilder.create(where: filter_fn)
  end

  @doc """
  Constrói uma consulta complexa combinando múltiplos critérios.

  ## Parâmetros

    * `opts` - Opções de filtragem

  ## Opções

    * `:prefix` - Prefixo das chaves
    * `:namespace` - Namespace das chaves
    * `:pattern` - Padrão regex para chaves
    * `:min_ttl` - TTL mínimo em segundos
    * `:max_ttl` - TTL máximo em segundos
    * `:include_expired` - Se deve incluir entradas expiradas

  ## Retorno

    * Estrutura de consulta do Cachex

  ## Exemplos

      iex> query = DeeperHub.Core.Cache.Queries.AdvancedQuery.composite(
      ...>   prefix: "user:",
      ...>   min_ttl: 60,
      ...>   max_ttl: 3600
      ...> )
      iex> Cachex.stream(:deeper_hub_cache, query)
  """
  @spec composite(keyword()) :: Cachex.Query.t()
  def composite(opts) do
    prefix = Keyword.get(opts, :prefix)
    namespace = Keyword.get(opts, :namespace)
    pattern = Keyword.get(opts, :pattern)
    min_ttl = Keyword.get(opts, :min_ttl)
    max_ttl = Keyword.get(opts, :max_ttl)
    include_expired = Keyword.get(opts, :include_expired, false)

    # Constrói condição baseada nas opções fornecidas
    QueryBuilder.create(
      where: fn {key, value} ->
        # Verifica se é uma string para evitar erros em operações de string
        key_check = is_binary(key) &&
                    # Verifica prefixo se fornecido
                    (prefix == nil || String.starts_with?(key, prefix)) &&
                    # Verifica namespace se fornecido
                    (namespace == nil || String.starts_with?(key, "#{namespace}:")) &&
                    # Verifica padrão regex se fornecido
                    (pattern == nil || Regex.match?(pattern, key))

        # Se a chave não passa no teste, retorna falso imediatamente
        key_check && (
          # Verifica expiração se solicitado
          (include_expired || not is_entry_expired?(value)) &&
          # Verifica TTL mínimo se fornecido
          check_min_ttl(value, min_ttl) &&
          # Verifica TTL máximo se fornecido
          check_max_ttl(value, max_ttl)
        )
      end
    )
  end

  # Funções privadas

  # Verifica se uma entrada está expirada
  defp is_entry_expired?(entry) do
    # Verifica expiração com base na estrutura interna do Cachex
    case get_ttl(entry) do
      0 -> true
      ttl when is_integer(ttl) and ttl < 0 -> true
      _ -> false
    end
  end

  # Extrai o TTL de uma entrada do cache
  defp get_ttl(entry) do
    cond do
      # Entradas sem TTL
      is_map(entry) && Map.has_key?(entry, :ttl) ->
        entry.ttl

      # Entradas com TTL absoluto
      is_map(entry) && Map.has_key?(entry, :touched) && Map.has_key?(entry, :expiration) ->
        now = System.os_time(:second)
        entry.expiration - now

      # Se não conseguimos extrair o TTL
      true -> nil
    end
  end

  # Verifica se o TTL está acima do mínimo
  defp check_min_ttl(_entry, nil), do: true
  defp check_min_ttl(entry, min_ttl) do
    case get_ttl(entry) do
      nil -> true
      :infinity -> true
      ttl when is_integer(ttl) -> ttl >= min_ttl
      _ -> false
    end
  end

  # Verifica se o TTL está abaixo do máximo
  defp check_max_ttl(_entry, nil), do: true
  defp check_max_ttl(entry, max_ttl) do
    case get_ttl(entry) do
      nil -> true
      :infinity -> false
      ttl when is_integer(ttl) -> ttl <= max_ttl
      _ -> false
    end
  end
end
