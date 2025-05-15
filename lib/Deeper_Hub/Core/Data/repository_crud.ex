defmodule Deeper_Hub.Core.Data.RepositoryCrud do
  @moduledoc """
  Módulo para operações CRUD (Create, Read, Update, Delete) no repositório.
  
  Este módulo fornece funções para realizar operações básicas de banco de dados,
  como inserção, consulta, atualização e exclusão de registros, além de funções
  para listar e buscar registros com condições específicas.
  
  Utiliza o pool de conexões gerenciado pela biblioteca DBConnection para otimizar
  o uso de recursos e melhorar o desempenho das operações de banco de dados.
  """

  import Ecto.Query
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.RepositoryCore
  alias Deeper_Hub.Core.Data.DBConnection.DBConnectionFacade, as: DBConn

  @doc """
  Executa uma função dentro de uma transação do banco de dados.
  
  Utiliza o pool de conexões gerenciado pela biblioteca DBConnection para
  garantir o uso eficiente das conexões e o isolamento das operações.
  
  ## Parâmetros
  
    - `fun`: Função a ser executada dentro da transação
    - `opts`: Opções para a transação
  
  ## Retorno
  
    - `{:ok, result}`: Resultado da função se a transação for bem-sucedida
    - `{:error, reason}`: Erro se a transação falhar
  
  ## Exemplo
  
  ```elixir
  RepositoryCrud.transaction(fn ->
    {:ok, user} = RepositoryCrud.insert(User, %{name: "Alice"})
    {:ok, _} = RepositoryCrud.insert(Log, %{action: "user_created", user_id: user.id})
    user
  end)
  ```
  """
  @spec transaction((-> any()), Keyword.t()) :: {:ok, any()} | {:error, any()}
  def transaction(fun, opts \\ []) do
    start_time = System.monotonic_time()
    
    Logger.debug("Iniciando transação", %{
      module: __MODULE__
    })
    
    # Usa o DBConnectionFacade para gerenciar a transação
    result = DBConn.transaction(fun, opts)
    
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    case result do
      {:ok, value} ->
        Logger.debug("Transação concluída com sucesso", %{
          module: __MODULE__,
          duration_ms: duration_ms
        })
        
        {:ok, value}
        
      {:error, reason} ->
        Logger.error("Erro na transação", %{
          module: __MODULE__,
          reason: inspect(reason),
          duration_ms: duration_ms
        })
        
        {:error, reason}
    end
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
    # Início da operação de inserção

    # Registra a operação
    Logger.debug("Inserindo registro", %{
      module: __MODULE__,
      schema: schema,
      attrs: attrs
    })

    # Cria um changeset e insere dentro de uma transação
    result = transaction(fn ->
      changeset = schema
        |> struct()
        |> schema.changeset(attrs)
      
      case Repo.insert(changeset) do
        {:ok, struct} -> struct
        {:error, changeset} -> DBConn.rollback(nil, changeset)
      end
    end)

    # Processa o resultado da transação
    case result do
      {:ok, struct} ->
        id = Map.get(struct, :id)
        Logger.debug("Registro inserido com sucesso", %{
          module: __MODULE__,
          schema: schema,
          id: id
        })

        # Armazena no cache para futuras consultas
        RepositoryCore.put_in_cache(schema, id, struct)
        
        {:ok, struct}

      {:error, changeset} ->
        Logger.error("Falha ao inserir registro", %{
          module: __MODULE__,
          schema: schema,
          errors: changeset.errors
        })
        
        {:error, changeset}
    end
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
    # Início da operação de busca

    # Registra a operação
    Logger.debug("Buscando registro por ID", %{
      module: __MODULE__,
      schema: schema,
      id: id
    })

    # Verifica se o registro está no cache
    result = case RepositoryCore.get_from_cache(schema, id) do
      {:ok, value} ->
        # Registra que o valor foi encontrado no cache
        Logger.debug("Registro encontrado no cache", %{
          module: __MODULE__,
          schema: schema,
          id: id
        })

        # Registro encontrado no cache

        {:ok, value}

      :not_found ->
        # Busca no banco de dados
        case Repo.get(schema, id) do
          nil ->
            # Registro não encontrado no banco de dados

            {:error, :not_found}

          record ->
            # Armazena no cache para futuras consultas
            RepositoryCore.put_in_cache(schema, id, record)

            # Registro encontrado no banco de dados

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

    # Finaliza operação de busca

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
    # Início da operação de atualização
    start_time = System.monotonic_time()

    # Registra a operação
    Logger.debug("Atualizando registro", %{
      module: __MODULE__,
      schema: struct.__struct__,
      id: Map.get(struct, :id),
      attrs: attrs
    })

    # Cria um changeset e atualiza dentro de uma transação
    result = transaction(fn ->
      changeset = struct.__struct__.changeset(struct, attrs)
      
      case Repo.update(changeset) do
        {:ok, updated_struct} -> updated_struct
        {:error, changeset} -> DBConn.rollback(nil, changeset)
      end
    end)

    # Calcula a duração da operação
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)

    # Processa o resultado da transação
    case result do
      {:ok, updated_struct} ->
        id = Map.get(updated_struct, :id)
        Logger.debug("Registro atualizado com sucesso", %{
          module: __MODULE__,
          schema: struct.__struct__,
          id: id,
          duration_ms: duration_ms
        })

        # Atualiza o cache
        RepositoryCore.put_in_cache(struct.__struct__, id, updated_struct)
        
        {:ok, updated_struct}

      {:error, changeset} ->
        Logger.error("Falha ao atualizar registro", %{
          module: __MODULE__,
          schema: struct.__struct__,
          id: Map.get(struct, :id),
          errors: changeset.errors,
          duration_ms: duration_ms
        })
        
        {:error, changeset}
    end
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
    # Início da operação de exclusão
    start_time = System.monotonic_time()
    
    # Obtém o ID para referência
    id = Map.get(struct, :id)

    # Registra a operação
    Logger.debug("Removendo registro", %{
      module: __MODULE__,
      schema: struct.__struct__,
      id: id
    })

    # Remove o registro dentro de uma transação
    result = transaction(fn ->
      case Repo.delete(struct) do
        {:ok, _deleted_struct} -> 
          # Retorna o ID para referência após a exclusão
          id
        {:error, changeset} -> 
          # Aborta a transação em caso de erro
          DBConn.rollback(nil, changeset)
      end
    end)
    
    # Calcula a duração da operação
    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)

    # Processa o resultado da transação
    case result do
      {:ok, deleted_id} ->
        # Invalida o cache após exclusão bem-sucedida
        RepositoryCore.invalidate_cache(struct.__struct__, deleted_id)
        
        Logger.debug("Registro removido com sucesso", %{
          module: __MODULE__,
          schema: struct.__struct__,
          id: deleted_id,
          duration_ms: duration_ms
        })
        
        {:ok, :deleted}

      {:error, changeset} ->
        Logger.error("Falha ao remover registro", %{
          module: __MODULE__,
          schema: struct.__struct__,
          id: id,
          errors: changeset.errors,
          duration_ms: duration_ms
        })
        
        {:error, changeset}
    end
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
      {:ok, users} = RepositoryCrud.list(User)

      # Listar com paginação (limite de 10 registros)
      {:ok, users} = RepositoryCrud.list(User, limit: 10, offset: 0)

      # Listar com pré-carregamento de associações
      {:ok, users} = RepositoryCrud.list(User, preload: [:profile, :posts])
  """
  @spec list(module(), Keyword.t()) :: {:ok, list(Ecto.Schema.t())} | {:error, term()}
  def list(schema, opts \\ []) do
    # Início da operação de listagem

    query_start_time = System.monotonic_time()

    # Registra a operação
    Logger.debug("Listando registros", %{
      module: __MODULE__,
      schema: schema,
      opts: opts
    })

    result = try do
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
      query = RepositoryCore.apply_limit_offset(query, opts)

      # Executa a query
      records = Repo.all(query)

      # Registra o resultado
      Logger.debug("Registros listados com sucesso", %{
        module: __MODULE__,
        schema: schema,
        count: length(records),
        duration_ms: System.convert_time_unit(System.monotonic_time() - query_start_time, :native, :millisecond)
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

        # Tabela não encontrada

        {:error, :table_not_found}

      e ->
        # Outros erros
        Logger.error("Falha ao listar registros", %{
          module: __MODULE__,
          schema: schema,
          error: e,
          stacktrace: __STACKTRACE__
        })

        # Erro ao listar registros

        {:error, e}
    end

    # Finaliza operação de listagem

    result
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
      {:ok, users} = RepositoryCrud.find(User, %{name: "João"})

      # Buscar com múltiplas condições
      {:ok, users} = RepositoryCrud.find(User, %{name: "João", active: true})

      # Com paginação
      {:ok, users} = RepositoryCrud.find(User, %{active: true}, limit: 10, offset: 0)
  """
  @spec find(module(), map(), Keyword.t()) :: {:ok, list(Ecto.Schema.t())} | {:error, term()}
  def find(schema, conditions, opts \\ []) when is_map(conditions) do
    # Início da operação de busca com condições
    query_start_time = System.monotonic_time()

    # Registra a operação
    Logger.debug("Buscando registros por condições", %{
      module: __MODULE__,
      schema: schema,
      conditions: conditions,
      opts: opts
    })
    
    # Usa o pool de conexões gerenciado pelo DBConnection para executar a consulta
    # Isso garante que a conexão será devolvida ao pool após o uso
    result = DBConn.run(nil, fn ->
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
            from(item in acc_query, where: like(fragment("lower(?)", field(item, ^field_name)), ^String.downcase("%#{term}%")))

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
        query = RepositoryCore.apply_limit_offset(query, opts)

        # Executa a query usando a conexão do pool
        records = Repo.all(query)
        
        # Retorna os registros encontrados
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

          # Tabela não encontrada
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

          # Condições de busca inválidas
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

          # Erro ao buscar registros
          {:error, e}
      end
    end)
    
    # Calcula a duração total da operação
    duration = System.monotonic_time() - query_start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    # Registra o resultado final com métricas
    case result do
      {:ok, records} ->
        Logger.debug("Registros encontrados com sucesso", %{
          module: __MODULE__,
          schema: schema,
          conditions: conditions,
          count: length(records),
          duration_ms: duration_ms
        })
        
      {:error, reason} ->
        Logger.debug("Busca finalizada com erro", %{
          module: __MODULE__,
          schema: schema,
          reason: inspect(reason),
          duration_ms: duration_ms
        })
    end
    
    # Retorna o resultado da operação
    result
  end
end
