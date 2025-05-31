defmodule DeeperHub.DataAccess.Operations.UserOperations do
  @moduledoc """
  Módulo para operações relacionadas a usuários no DeeperHub.
  
  Este módulo fornece funções para criar, buscar, atualizar e excluir
  usuários no sistema, encapsulando a lógica de acesso ao banco de dados
  e garantindo a integridade dos dados.
  """
  
  import Ecto.Query
  alias DeeperHub.DataAccess.Repo
  alias DeeperHub.DataAccess.Schemas.User
  require DeeperHub.Logger
  
  @doc """
  Cria um novo usuário no sistema.
  
  ## Parâmetros
    - attrs: Mapa contendo os atributos do usuário a ser criado
    
  ## Retorno
    - `{:ok, user}` em caso de sucesso, onde `user` é o usuário criado
    - `{:error, changeset}` em caso de erro de validação
    - `{:error, :database_error, reason}` em caso de erro de banco de dados
  """
  def create(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
    |> handle_database_result("Erro ao criar usuário")
  end
  
  @doc """
  Busca um usuário pelo ID.
  
  ## Parâmetros
    - id: ID do usuário a ser buscado
    
  ## Retorno
    - `{:ok, user}` se o usuário for encontrado
    - `{:error, :not_found}` se o usuário não for encontrado
    - `{:error, :database_error, reason}` em caso de erro de banco de dados
  """
  def get(id) do
    try do
      case Repo.get(User, id) do
        nil -> {:error, :not_found}
        user -> {:ok, user}
      end
    rescue
      e -> handle_exception(e, "Erro ao buscar usuário por ID")
    end
  end
  
  @doc """
  Busca um usuário pelo nome de usuário.
  
  ## Parâmetros
    - username: Nome de usuário a ser buscado
    
  ## Retorno
    - `{:ok, user}` se o usuário for encontrado
    - `{:error, :not_found}` se o usuário não for encontrado
    - `{:error, :database_error, reason}` em caso de erro de banco de dados
  """
  def get_by_username(username) do
    try do
      case Repo.get_by(User, username: username) do
        nil -> {:error, :not_found}
        user -> {:ok, user}
      end
    rescue
      e -> handle_exception(e, "Erro ao buscar usuário por nome de usuário")
    end
  end
  
  @doc """
  Busca um usuário pelo email.
  
  ## Parâmetros
    - email: Email a ser buscado
    
  ## Retorno
    - `{:ok, user}` se o usuário for encontrado
    - `{:error, :not_found}` se o usuário não for encontrado
    - `{:error, :database_error, reason}` em caso de erro de banco de dados
  """
  def get_by_email(email) do
    try do
      case Repo.get_by(User, email: email) do
        nil -> {:error, :not_found}
        user -> {:ok, user}
      end
    rescue
      e -> handle_exception(e, "Erro ao buscar usuário por email")
    end
  end
  
  @doc """
  Lista todos os usuários do sistema.
  
  ## Parâmetros
    - opts: Opções para filtrar, ordenar e paginar os resultados
      - `:limit` - Número máximo de registros a retornar (padrão: 100)
      - `:offset` - Número de registros a pular (padrão: 0)
      - `:order_by` - Campo para ordenação (padrão: :inserted_at)
      - `:order_direction` - Direção da ordenação: :asc ou :desc (padrão: :desc)
      - `:filter` - Mapa com filtros a serem aplicados
    
  ## Retorno
    - `{:ok, users}` lista de usuários encontrados (pode estar vazia)
    - `{:error, :database_error, reason}` em caso de erro de banco de dados
  """
  def list(opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)
    order_by = Keyword.get(opts, :order_by, :inserted_at)
    order_direction = Keyword.get(opts, :order_direction, :desc)
    filter = Keyword.get(opts, :filter, %{})
    
    DeeperHub.Logger.debug("Listando usuários com opções: #{inspect(opts)}")
    
    try do
      query = from(u in User)
      
      # Aplica filtros se existirem
      query = apply_filters(query, filter)
      
      # Aplica ordenação
      query = from(u in query, order_by: [{^order_direction, field(u, ^order_by)}])
      
      # Aplica paginação
      query = from(u in query, limit: ^limit, offset: ^offset)
      
      users = Repo.all(query)
      {:ok, users}
    rescue
      e -> handle_exception(e, "Erro ao listar usuários")
    end
  end
  
  @doc """
  Atualiza os dados de um usuário existente.
  
  ## Parâmetros
    - user: Struct do usuário a ser atualizado
    - attrs: Mapa contendo os atributos a serem atualizados
    
  ## Retorno
    - `{:ok, updated_user}` em caso de sucesso
    - `{:error, changeset}` em caso de erro de validação
    - `{:error, :database_error, reason}` em caso de erro de banco de dados
  """
  def update(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
    |> handle_database_result("Erro ao atualizar usuário")
  end
  
  @doc """
  Atualiza os dados de um usuário pelo ID.
  
  ## Parâmetros
    - id: ID do usuário a ser atualizado
    - attrs: Mapa contendo os atributos a serem atualizados
    
  ## Retorno
    - `{:ok, updated_user}` em caso de sucesso
    - `{:error, :not_found}` se o usuário não for encontrado
    - `{:error, changeset}` em caso de erro de validação
    - `{:error, :database_error, reason}` em caso de erro de banco de dados
  """
  def update_by_id(id, attrs) do
    # Inicia uma transação para garantir a atomicidade da operação
    result = Repo.transaction(fn ->
      # Busca o usuário pelo ID dentro da transação
      case Repo.get(User, id) do
        nil -> 
          Repo.rollback(:not_found)
        user -> 
          # Cria um changeset e tenta atualizar
          user
          |> User.changeset(attrs)
          |> Repo.update()
          |> case do
            {:ok, updated_user} -> updated_user
            {:error, changeset} -> Repo.rollback(changeset)
          end
      end
    end)
    
    # Trata o resultado da transação
    case result do
      {:ok, user} -> {:ok, user}
      {:error, :not_found} -> {:error, :not_found}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Remove um usuário do sistema.
  
  ## Parâmetros
    - user: Struct do usuário a ser removido
    
  ## Retorno
    - `{:ok, deleted_user}` em caso de sucesso
    - `{:error, changeset}` em caso de erro
    - `{:error, :database_error, reason}` em caso de erro de banco de dados
  """
  def delete(user) do
    user
    |> Repo.delete()
    |> handle_database_result("Erro ao remover usuário")
  end
  
  @doc """
  Remove um usuário pelo ID.
  
  ## Parâmetros
    - id: ID do usuário a ser removido
    
  ## Retorno
    - `{:ok, deleted_user}` em caso de sucesso
    - `{:error, :not_found}` se o usuário não for encontrado
    - `{:error, changeset}` em caso de erro
    - `{:error, :database_error, reason}` em caso de erro de banco de dados
  """
  def delete_by_id(id) do
    Repo.transaction(fn ->
      with {:ok, user} <- get(id),
           {:ok, deleted_user} <- delete(user) do
        deleted_user
      else
        {:error, reason} -> Repo.rollback(reason)
        error -> Repo.rollback(error)
      end
    end)
    |> handle_transaction_result()
  end
  
  # Funções privadas auxiliares
  
  # Aplica filtros à query
  defp apply_filters(query, filters) when is_map(filters) and map_size(filters) == 0, do: query
  defp apply_filters(query, filters) when is_map(filters) do
    Enum.reduce(filters, query, fn
      {:active, value}, query ->
        from(u in query, where: u.active == ^value)
      
      {:name, value}, query when is_binary(value) and value != "" ->
        from(u in query, where: ilike(u.name, ^"%#{value}%"))
      
      {:email, value}, query when is_binary(value) and value != "" ->
        from(u in query, where: ilike(u.email, ^"%#{value}%"))
      
      {:username, value}, query when is_binary(value) and value != "" ->
        from(u in query, where: ilike(u.username, ^"%#{value}%"))
      
      _, query -> query
    end)
  end
  
  # Trata o resultado de operações no banco de dados
  defp handle_database_result({:ok, result}, _error_message) do
    {:ok, result}
  end
  
  defp handle_database_result({:error, %Ecto.Changeset{} = changeset}, error_message) do
    DeeperHub.Logger.error("#{error_message}: #{inspect(changeset.errors)}")
    {:error, changeset}
  end
  
  defp handle_database_result({:error, error}, error_message) do
    DeeperHub.Logger.error("#{error_message}: #{inspect(error)}")
    {:error, :database_error, error}
  end
  
  # Trata o resultado de uma transação
  defp handle_transaction_result({:ok, result}), do: {:ok, result}
  defp handle_transaction_result({:error, :not_found}), do: {:error, :not_found}
  defp handle_transaction_result({:error, %Ecto.Changeset{} = changeset}), do: {:error, changeset}
  defp handle_transaction_result({:error, error}), do: {:error, error}
  
  # Trata exceções durante operações de banco de dados
  defp handle_exception(exception, error_message) do
    DeeperHub.Logger.error("#{error_message}: #{inspect(exception)}")
    {:error, :database_error, exception}
  end
end
