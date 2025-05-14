defmodule Deeper_Hub.Core.Data.Repository do
  use GenServer
  @moduledoc """
  Repositório genérico para operações CRUD.

  Este módulo fornece uma interface genérica para operações de CRUD
  (Create, Read, Update, Delete) em qualquer schema do Ecto.
  Inclui funcionalidades de cache para melhorar o desempenho de consultas repetitivas.
  """

  import Ecto.Query
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics.DatabaseMetrics

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

  defp get_from_cache(schema, id) do
    # Garante que o cache está inicializado antes de qualquer operação
    ensure_cache_initialized()

    # Verifica se o valor está no cache
    case :ets.lookup(@cache_table, cache_key(schema, id)) do
      [{_, value}] ->
        # Incrementa contador de hits
        # Otimização: Usar :ets.update_counter em vez de lookup + insert
        :ets.update_counter(@cache_stats, :hits, 1)
        {:ok, value}
      [] ->
        # Incrementa contador de misses
        # Otimização: Usar :ets.update_counter em vez de lookup + insert
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

  defp put_in_cache(schema, id, value) do
    # Garante que o cache está inicializado antes de qualquer operação
    ensure_cache_initialized()

    # Armazena o valor no cache
    :ets.insert(@cache_table, {cache_key(schema, id), value})
    :ok
  end

  defp invalidate_cache(schema, id) do
    # Garante que o cache está inicializado antes de qualquer operação
    ensure_cache_initialized()

    # Remove o valor do cache
    :ets.delete(@cache_table, cache_key(schema, id))
    :ok
  end

  @doc """
  Insere um novo registro no banco de dados.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `attrs`: Os atributos para inserir

  ## Retorno

    - `{:ok, struct}` se a inserção for bem-sucedida
    - `{:error, changeset}` em caso de falha
  """
  @spec insert(module(), map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def insert(schema, attrs) do
    start_time = System.monotonic_time()

    # Registra a operação
    Logger.debug("Inserindo registro", %{
      module: __MODULE__,
      schema: schema,
      attrs: attrs
    })

    # Cria um changeset e insere
    result = schema
    |> struct()
    |> schema.changeset(attrs)
    |> Repo.insert()

    # Registra métricas
    DatabaseMetrics.record_operation_time(:insert, schema, System.monotonic_time() - start_time)
    DatabaseMetrics.record_operation_result(:insert, schema, result)

    # Registra o resultado
    case result do
      {:ok, struct} ->
        id = Map.get(struct, :id)
        Logger.debug("Registro inserido com sucesso", %{
          module: __MODULE__,
          schema: schema,
          id: id
        })

        # Armazena no cache para futuras consultas
        put_in_cache(schema, id, struct)

      {:error, changeset} ->
        Logger.error("Falha ao inserir registro", %{
          module: __MODULE__,
          schema: schema,
          errors: changeset.errors
        })
    end

    result
  end

  @doc """
  Busca um registro pelo ID.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `id`: O ID do registro a ser buscado

  ## Retorno

    - `{:ok, struct}` se o registro for encontrado
    - `{:error, :not_found}` se o registro não for encontrado
  """
  @spec get(module(), term()) :: {:ok, Ecto.Schema.t()} | {:error, :not_found}
  def get(schema, id) do
    start_time = System.monotonic_time()

    # Registra a operação
    Logger.debug("Buscando registro por ID", %{
      module: __MODULE__,
      schema: schema,
      id: id
    })

    # Verifica se o registro está no cache
    result = case get_from_cache(schema, id) do
      {:ok, value} ->
        # Registra que o valor foi encontrado no cache
        Logger.debug("Registro encontrado no cache", %{
          module: __MODULE__,
          schema: schema,
          id: id
        })

        # Registra métricas
        DatabaseMetrics.record_operation_time(:get, schema, System.monotonic_time() - start_time)
        DatabaseMetrics.record_operation_result(:get, schema, {:ok, value})

        {:ok, value}

      :not_found ->
        # Busca no banco de dados
        case Repo.get(schema, id) do
          nil ->
            # Registra métricas
            DatabaseMetrics.record_operation_time(:get, schema, System.monotonic_time() - start_time)
            DatabaseMetrics.record_operation_result(:get, schema, {:error, :not_found})

            {:error, :not_found}

          record ->
            # Armazena no cache para futuras consultas
            put_in_cache(schema, id, record)

            # Registra métricas
            DatabaseMetrics.record_operation_time(:get, schema, System.monotonic_time() - start_time)
            DatabaseMetrics.record_operation_result(:get, schema, {:ok, record})

            {:ok, record}
        end
    end

    # Registra o resultado
    case result do
      {:ok, _} ->
        Logger.debug("Registro encontrado", %{
          module: __MODULE__,
          schema: schema,
          id: id
        })

      {:error, :not_found} ->
        Logger.debug("Registro não encontrado", %{
          module: __MODULE__,
          schema: schema,
          id: id
        })
    end

    result
  end

  @doc """
  Atualiza um registro existente.

  ## Parâmetros

    - `struct`: A struct a ser atualizada
    - `attrs`: Os atributos para atualizar

  ## Retorno

    - `{:ok, struct}` se a atualização for bem-sucedida
    - `{:error, changeset}` em caso de falha
  """
  @spec update(Ecto.Schema.t(), map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def update(struct, attrs) do
    start_time = System.monotonic_time()
    schema = struct.__struct__
    id = Map.get(struct, :id)

    # Registra a operação
    Logger.debug("Atualizando registro", %{
      module: __MODULE__,
      schema: schema,
      id: id,
      attrs: attrs
    })

    # Cria um changeset e atualiza
    result = struct
    |> schema.changeset(attrs)
    |> Repo.update()

    # Registra métricas
    DatabaseMetrics.record_operation_time(:update, schema, System.monotonic_time() - start_time)
    DatabaseMetrics.record_operation_result(:update, schema, result)

    # Registra o resultado
    case result do
      {:ok, updated_struct} ->
        Logger.debug("Registro atualizado com sucesso", %{
          module: __MODULE__,
          schema: schema,
          id: id
        })

        # Atualiza o cache
        put_in_cache(schema, id, updated_struct)

      {:error, changeset} ->
        Logger.error("Falha ao atualizar registro", %{
          module: __MODULE__,
          schema: schema,
          id: id,
          errors: changeset.errors
        })
    end

    result
  end

  @doc """
  Remove um registro existente.

  ## Parâmetros

    - `struct`: A struct a ser removida

  ## Retorno

    - `{:ok, :deleted}` se a remoção for bem-sucedida
    - `{:error, changeset}` em caso de falha
  """
  @spec delete(Ecto.Schema.t()) :: {:ok, :deleted} | {:error, Ecto.Changeset.t()}
  def delete(struct) do
    start_time = System.monotonic_time()
    schema = struct.__struct__
    id = Map.get(struct, :id)

    # Registra a operação
    Logger.debug("Removendo registro", %{
      module: __MODULE__,
      schema: schema,
      id: id
    })

    # Remove o registro
    result = case Repo.delete(struct) do
      {:ok, _} ->
        # Invalida o cache
        invalidate_cache(schema, id)

        {:ok, :deleted}

      {:error, changeset} ->
        {:error, changeset}
    end

    # Registra métricas
    DatabaseMetrics.record_operation_time(:delete, schema, System.monotonic_time() - start_time)
    DatabaseMetrics.record_operation_result(:delete, schema, result)

    # Registra o resultado
    case result do
      {:ok, :deleted} ->
        Logger.debug("Registro removido com sucesso", %{
          module: __MODULE__,
          schema: schema,
          id: id
        })

      {:error, changeset} ->
        Logger.error("Falha ao remover registro", %{
          module: __MODULE__,
          schema: schema,
          id: id,
          errors: changeset.errors
        })
    end

    result
  end

  @doc """
  Lista todos os registros de um schema.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `opts`: Opções adicionais (como limit, offset, preload, etc.)

  ## Retorno

    - `{:ok, list}` com a lista de registros
    - `{:error, reason}` em caso de falha

  ## Exemplo

      # Listar todos os usuários
      {:ok, users} = Repository.list(User)

      # Listar com paginação (limite de 10 registros)
      {:ok, users} = Repository.list(User, limit: 10, offset: 0)

      # Listar com pré-carregamento de associações
      {:ok, users} = Repository.list(User, preload: [:profile, :posts])
  """
  @spec list(module(), Keyword.t()) :: {:ok, list(Ecto.Schema.t())} | {:error, term()}
  def list(schema, opts \\ []) do
    start_time = System.monotonic_time()

    # Registra a operação
    Logger.debug("Listando registros", %{
      module: __MODULE__,
      schema: schema,
      opts: opts
    })

    try do
      # Constrói a query base
      query = from(item in schema)

      # Aplica pré-carregamento se especificado
      query = case Keyword.get(opts, :preload) do
        nil -> query
        preloads -> Ecto.Query.preload(query, ^preloads)
      end

      # Ordenação padrão por ID ascendente se não for especificada
      query = if Keyword.has_key?(opts, :order_by) do
        order_by = Keyword.get(opts, :order_by, asc: :id)
        from(item in query, order_by: ^order_by)
      else
        from(item in query, order_by: [asc: item.id])
      end

      # Aplica limit e offset se fornecidos
      query = apply_limit_offset(query, opts)

      # Executa a query
      records = Repo.all(query)

      # Registra métricas
      duration = System.monotonic_time() - start_time
      DatabaseMetrics.record_operation_time(:list, schema, duration)
      DatabaseMetrics.record_operation_result(:list, schema, {:ok, records})
      DatabaseMetrics.record_result_size(:list, schema, length(records))

      # Registra o resultado
      Logger.debug("Registros listados com sucesso", %{
        module: __MODULE__,
        schema: schema,
        count: length(records),
        duration_ms: System.convert_time_unit(duration, :native, :millisecond)
      })

      {:ok, records}
    rescue
      e in [UndefinedFunctionError] ->
        # Tabela pode não existir
        error_msg = "Tabela para schema #{inspect(schema)} não encontrada"
        Logger.error(error_msg, %{
          module: __MODULE__,
          schema: schema,
          error: e,
          stacktrace: __STACKTRACE__
        })

        # Registra métricas
        DatabaseMetrics.record_operation_time(:list, schema, System.monotonic_time() - start_time)
        DatabaseMetrics.record_operation_result(:list, schema, {:error, :table_not_found})

        {:error, :table_not_found}

      e ->
        # Outros erros
        Logger.error("Falha ao listar registros", %{
          module: __MODULE__,
          schema: schema,
          error: e,
          stacktrace: __STACKTRACE__
        })

        # Registra métricas
        DatabaseMetrics.record_operation_time(:list, schema, System.monotonic_time() - start_time)
        DatabaseMetrics.record_operation_result(:list, schema, {:error, e})

        {:error, e}
    end
  end

  # Aplica limit e offset a uma query
  defp apply_limit_offset(query, opts) do
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

  @doc """
  Busca registros com base em condições.

  ## Parâmetros

    - `schema`: O módulo do schema Ecto
    - `conditions`: Mapa com as condições de busca
    - `opts`: Opções adicionais (como limit, offset, preload, etc.)

  ## Retorno

    - `{:ok, list}` com a lista de registros
    - `{:error, reason}` em caso de falha

  ## Exemplo

      # Buscar usuários por nome
      {:ok, users} = Repository.find(User, %{name: "João"})

      # Buscar com múltiplas condições
      {:ok, users} = Repository.find(User, %{name: "João", active: true})

      # Com paginação
      {:ok, users} = Repository.find(User, %{active: true}, limit: 10, offset: 0)
  """
  @spec find(module(), map(), Keyword.t()) :: {:ok, list(Ecto.Schema.t())} | {:error, term()}
  def find(schema, conditions, opts \\ []) when is_map(conditions) do
    start_time = System.monotonic_time()

    # Registra a operação
    Logger.debug("Buscando registros por condições", %{
      module: __MODULE__,
      schema: schema,
      conditions: conditions,
      opts: opts
    })

    try do
      # Constrói a query base
      query = from(item in schema)

      # Aplica as condições
      query = Enum.reduce(conditions, query, fn
        {field_name, nil}, acc_query ->
          # Trata valores nulos corretamente
          from(item in acc_query, where: is_nil(field(item, ^field_name)))

        {field_name, :not_nil}, acc_query ->
          # Busca por valores não nulos
          from(item in acc_query, where: not is_nil(field(item, ^field_name)))

        {field_name, {:in, values}}, acc_query ->
          # Busca por valores em uma lista (IN)
          if is_list(values) do
            from(item in acc_query, where: field(item, ^field_name) in ^values)
          else
            acc_query
          end

        {field_name, {:not_in, values}}, acc_query ->
          # Exclui valores em uma lista (NOT IN)
          if is_list(values) do
            from(item in acc_query, where: field(item, ^field_name) not in ^values)
          else
            acc_query
          end

        {field_name, {:like, term}}, acc_query ->
          # Busca com LIKE (case-sensitive)
          from(item in acc_query, where: like(field(item, ^field_name), ^"%#{term}%"))

        {field_name, {:ilike, term}}, acc_query ->
          # Busca com ILIKE (case-insensitive)
          from(item in acc_query, where: ilike(field(item, ^field_name), ^"%#{term}%"))

        {field_name, value}, acc_query ->
          # Igualdade simples
          from(item in acc_query, where: field(item, ^field_name) == ^value)
      end)

      # Aplica pré-carregamento se especificado
      query = case Keyword.get(opts, :preload) do
        nil -> query
        preloads -> Ecto.Query.preload(query, ^preloads)
      end

      # Ordenação padrão por ID ascendente se não for especificada
      query = if Keyword.has_key?(opts, :order_by) do
        order_by = Keyword.get(opts, :order_by, asc: :id)
        from(item in query, order_by: ^order_by)
      else
        from(item in query, order_by: [asc: item.id])
      end

      # Aplica limit e offset se fornecidos
      query = apply_limit_offset(query, opts)

      # Executa a query
      records = Repo.all(query)

      # Registra métricas
      duration = System.monotonic_time() - start_time
      DatabaseMetrics.record_operation_time(:find, schema, duration)
      DatabaseMetrics.record_operation_result(:find, schema, {:ok, records})
      DatabaseMetrics.record_result_size(:find, schema, length(records))

      # Registra o resultado
      Logger.debug("Registros encontrados com sucesso", %{
        module: __MODULE__,
        schema: schema,
        conditions: conditions,
        count: length(records),
        duration_ms: System.convert_time_unit(duration, :native, :millisecond)
      })

      {:ok, records}
    rescue
      e in [UndefinedFunctionError] ->
        # Tabela pode não existir
        error_msg = "Tabela para schema #{inspect(schema)} não encontrada"
        Logger.error(error_msg, %{
          module: __MODULE__,
          schema: schema,
          error: e,
          stacktrace: __STACKTRACE__
        })

        # Registra métricas
        DatabaseMetrics.record_operation_time(:find, schema, System.monotonic_time() - start_time)
        DatabaseMetrics.record_operation_result(:find, schema, {:error, :table_not_found})

        {:error, :table_not_found}

      e in [CaseClauseError] ->
        # Condições inválidas
        error_msg = "Condições de busca inválidas: #{inspect(conditions)}"
        Logger.error(error_msg, %{
          module: __MODULE__,
          schema: schema,
          conditions: conditions,
          error: e,
          stacktrace: __STACKTRACE__
        })

        # Registra métricas
        DatabaseMetrics.record_operation_time(:find, schema, System.monotonic_time() - start_time)
        DatabaseMetrics.record_operation_result(:find, schema, {:error, :invalid_conditions})

        {:error, :invalid_conditions}

      e ->
        # Outros erros
        Logger.error("Falha ao buscar registros", %{
          module: __MODULE__,
          schema: schema,
          conditions: conditions,
          error: e,
          stacktrace: __STACKTRACE__
        })

        # Registra métricas
        DatabaseMetrics.record_operation_time(:find, schema, System.monotonic_time() - start_time)
        DatabaseMetrics.record_operation_result(:find, schema, {:error, e})

        {:error, e}
    end
  end
end
