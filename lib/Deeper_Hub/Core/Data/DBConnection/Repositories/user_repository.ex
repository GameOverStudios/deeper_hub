defmodule Deeper_Hub.Core.Data.DBConnection.Repositories.UserRepository do
  @moduledoc """
  Repositório para operações de banco de dados relacionadas a usuários.
  
  Este módulo implementa as operações CRUD para a entidade User,
  utilizando a fachada DBConnection para interagir com o banco de dados.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.DBConnection.Schemas.User
  alias Deeper_Hub.Core.Data.DBConnection.Facade, as: DB
  
  @doc """
  Insere um novo usuário no banco de dados.
  
  ## Parâmetros
  
    - `user`: A struct de usuário a ser inserida
  
  ## Retorno
  
    - `{:ok, user}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec insert(User.t()) :: {:ok, User.t()} | {:error, term()}
  def insert(user) do
    Logger.info("Inserindo usuário no banco de dados", %{
      module: __MODULE__,
      user_id: user.id
    })
    
    # Converte a struct para o formato do banco
    db_user = User.to_db(user)
    
    # Prepara a query de inserção
    query = """
    INSERT INTO #{User.table_name()} (
      id, username, email, password_hash, is_active, last_login, inserted_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """
    
    params = [
      db_user.id,
      db_user.username,
      db_user.email,
      db_user.password_hash,
      db_user.is_active,
      db_user.last_login,
      db_user.inserted_at,
      db_user.updated_at
    ]
    
    # Executa a query
    case DB.query(query, params) do
      {:ok, _} ->
        # Publica evento de usuário criado
        publish_user_created(user)
        
        {:ok, user}
      {:error, reason} ->
        Logger.error("Falha ao inserir usuário no banco de dados", %{
          module: __MODULE__,
          user_id: user.id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Atualiza um usuário existente no banco de dados.
  
  ## Parâmetros
  
    - `user`: A struct de usuário atualizada
  
  ## Retorno
  
    - `{:ok, user}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec update(User.t()) :: {:ok, User.t()} | {:error, term()}
  def update(user) do
    Logger.info("Atualizando usuário no banco de dados", %{
      module: __MODULE__,
      user_id: user.id
    })
    
    # Converte a struct para o formato do banco
    db_user = User.to_db(user)
    
    # Prepara a query de atualização
    query = """
    UPDATE #{User.table_name()}
    SET username = ?, email = ?, password_hash = ?, is_active = ?, 
        last_login = ?, updated_at = ?
    WHERE id = ?
    """
    
    params = [
      db_user.username,
      db_user.email,
      db_user.password_hash,
      db_user.is_active,
      db_user.last_login,
      db_user.updated_at,
      db_user.id
    ]
    
    # Executa a query
    case DB.query(query, params) do
      # Caso onde rows_affected é retornado
      {:ok, %{rows_affected: 1}} ->
        # Publica evento de usuário atualizado
        publish_user_updated(user)
        
        {:ok, user}
      {:ok, %{rows_affected: 0}} ->
        {:error, :not_found}
      # Caso onde rows e num_rows são retornados (SQLite)
      {:ok, %{rows: _, num_rows: _}} ->
        # Verifica se o usuário existe antes de considerar a atualização bem-sucedida
        case exists?(user.id) do
          {:ok, true} ->
            # Publica evento de usuário atualizado
            publish_user_updated(user)
            {:ok, user}
          {:ok, false} ->
            {:error, :not_found}
          error ->
            error
        end
      {:error, reason} ->
        Logger.error("Falha ao atualizar usuário no banco de dados", %{
          module: __MODULE__,
          user_id: user.id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Busca um usuário pelo ID.
  
  ## Parâmetros
  
    - `id`: O ID do usuário a ser buscado
  
  ## Retorno
  
    - `{:ok, user}` em caso de sucesso
    - `{:error, :not_found}` se o usuário não for encontrado
    - `{:error, reason}` em caso de falha
  """
  @spec get_by_id(String.t()) :: {:ok, User.t()} | {:error, term()}
  def get_by_id(id) do
    Logger.info("Buscando usuário por ID", %{
      module: __MODULE__,
      user_id: id
    })
    
    # Prepara a query
    query = "SELECT * FROM #{User.table_name()} WHERE id = ?"
    
    # Executa a query
    case DB.query(query, [id]) do
      {:ok, %{rows: [row]}} ->
        # Converte o resultado para struct
        user = User.from_db(row)
        {:ok, user}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        Logger.error("Falha ao buscar usuário por ID", %{
          module: __MODULE__,
          user_id: id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Busca um usuário pelo nome de usuário.
  
  ## Parâmetros
  
    - `username`: O nome de usuário a ser buscado
  
  ## Retorno
  
    - `{:ok, user}` em caso de sucesso
    - `{:error, :not_found}` se o usuário não for encontrado
    - `{:error, reason}` em caso de falha
  """
  @spec get_by_username(String.t()) :: {:ok, User.t()} | {:error, term()}
  def get_by_username(username) do
    Logger.info("Buscando usuário por nome de usuário", %{
      module: __MODULE__,
      username: username
    })
    
    # Prepara a query
    query = "SELECT * FROM #{User.table_name()} WHERE username = ?"
    
    # Executa a query
    case DB.query(query, [username]) do
      {:ok, %{rows: [row]}} ->
        # Converte o resultado para struct
        user = User.from_db(row)
        {:ok, user}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        Logger.error("Falha ao buscar usuário por nome de usuário", %{
          module: __MODULE__,
          username: username,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Busca um usuário pelo email.
  
  ## Parâmetros
  
    - `email`: O email a ser buscado
  
  ## Retorno
  
    - `{:ok, user}` em caso de sucesso
    - `{:error, :not_found}` se o usuário não for encontrado
    - `{:error, reason}` em caso de falha
  """
  @spec get_by_email(String.t()) :: {:ok, User.t()} | {:error, term()}
  def get_by_email(email) do
    Logger.info("Buscando usuário por email", %{
      module: __MODULE__,
      email: email
    })
    
    # Prepara a query
    query = "SELECT * FROM #{User.table_name()} WHERE email = ?"
    
    # Executa a query
    case DB.query(query, [email]) do
      {:ok, %{rows: [row]}} ->
        # Converte o resultado para struct
        user = User.from_db(row)
        {:ok, user}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        Logger.error("Falha ao buscar usuário por email", %{
          module: __MODULE__,
          email: email,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Lista todos os usuários.
  
  ## Parâmetros
  
    - `opts`: Opções de filtragem (opcional)
      - `:active_only` - Se `true`, retorna apenas usuários ativos
  
  ## Retorno
  
    - `{:ok, users}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec list_users(Keyword.t()) :: {:ok, [User.t()]} | {:error, term()}
  def list_users(opts \\ []) do
    Logger.info("Listando usuários", %{
      module: __MODULE__,
      opts: opts
    })
    
    # Prepara a query
    {query, params} = if Keyword.get(opts, :active_only, false) do
      {"SELECT * FROM #{User.table_name()} WHERE is_active = 1", []}
    else
      {"SELECT * FROM #{User.table_name()}", []}
    end
    
    # Executa a query
    case DB.query(query, params) do
      {:ok, %{rows: rows}} ->
        # Converte os resultados para structs
        users = Enum.map(rows, &User.from_db/1)
        {:ok, users}
      {:error, reason} ->
        Logger.error("Falha ao listar usuários", %{
          module: __MODULE__,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Desativa um usuário.
  
  ## Parâmetros
  
    - `id`: O ID do usuário a ser desativado
  
  ## Retorno
  
    - `{:ok, user}` em caso de sucesso
    - `{:error, :not_found}` se o usuário não for encontrado
    - `{:error, reason}` em caso de falha
  """
  @spec deactivate(String.t()) :: {:ok, User.t()} | {:error, term()}
  def deactivate(id) do
    with {:ok, user} <- get_by_id(id),
         {:ok, updated_user} <- User.update(user, %{is_active: false}) do
      update(updated_user)
    end
  end
  
  @doc """
  Reativa um usuário.
  
  ## Parâmetros
  
    - `id`: O ID do usuário a ser reativado
  
  ## Retorno
  
    - `{:ok, user}` em caso de sucesso
    - `{:error, :not_found}` se o usuário não for encontrado
    - `{:error, reason}` em caso de falha
  """
  @spec reactivate(String.t()) :: {:ok, User.t()} | {:error, term()}
  def reactivate(id) do
    with {:ok, user} <- get_by_id(id),
         {:ok, updated_user} <- User.update(user, %{is_active: true}) do
      update(updated_user)
    end
  end
  
  @doc """
  Exclui um usuário.
  
  ## Parâmetros
  
    - `id`: O ID do usuário a ser excluído
  
  ## Retorno
  
    - `{:ok, user_id}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec delete(String.t()) :: {:ok, String.t()} | {:error, term()}
  def delete(id) do
    Logger.info("Excluindo usuário", %{
      module: __MODULE__,
      user_id: id
    })
    
    # Busca o usuário primeiro para publicar o evento depois
    user_result = get_by_id(id)
    
    # Prepara a query
    query = "DELETE FROM #{User.table_name()} WHERE id = ?"
    
    # Executa a query
    case DB.query(query, [id]) do
      # Caso onde rows_affected é retornado
      {:ok, %{rows_affected: 1}} ->
        # Publica evento de usuário excluído se o usuário existia
        case user_result do
          {:ok, user} -> publish_user_deleted(user)
          _ -> :ok
        end
        
        {:ok, id}
      {:ok, %{rows_affected: 0}} ->
        {:error, :not_found}
      # Caso onde rows e num_rows são retornados (SQLite)
      {:ok, %{rows: _, num_rows: _}} ->
        # Se temos um usuário do get_by_id anterior, significa que ele existia
        case user_result do
          {:ok, user} ->
            publish_user_deleted(user)
            {:ok, id}
          {:error, :not_found} ->
            {:error, :not_found}
          _ ->
            # Verificamos novamente se o usuário ainda existe após a tentativa de exclusão
            case exists?(id) do
              {:ok, true} -> {:ok, id}  # Não foi excluído
              {:ok, false} -> {:ok, id}  # Foi excluído com sucesso
              error -> error
            end
        end
      {:error, reason} ->
        Logger.error("Falha ao excluir usuário", %{
          module: __MODULE__,
          user_id: id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Verifica se um usuário existe pelo ID.
  
  ## Parâmetros
  
    - `id`: O ID do usuário a ser verificado
  
  ## Retorno
  
    - `{:ok, true}` se o usuário existir
    - `{:ok, false}` se o usuário não existir
    - `{:error, reason}` em caso de falha
  """
  @spec exists?(String.t()) :: {:ok, boolean()} | {:error, term()}
  def exists?(id) do
    Logger.info("Verificando existência de usuário", %{
      module: __MODULE__,
      user_id: id
    })
    
    # Prepara a query
    query = "SELECT 1 FROM #{User.table_name()} WHERE id = ?"
    
    # Executa a query
    case DB.query(query, [id]) do
      {:ok, %{rows: []}} ->
        {:ok, false}
      {:ok, _} ->
        {:ok, true}
      {:error, reason} ->
        Logger.error("Falha ao verificar existência de usuário", %{
          module: __MODULE__,
          user_id: id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  # Funções privadas para publicação de eventos
  
  defp publish_user_created(user) do
    try do
      event_data = %{
        user_id: user.id,
        username: user.username,
        email: user.email,
        timestamp: DateTime.utc_now()
      }
      
      Deeper_Hub.Core.EventBus.publish(:user_created, event_data)
    rescue
      _ -> :ok
    end
  end
  
  defp publish_user_updated(user) do
    try do
      event_data = %{
        user_id: user.id,
        username: user.username,
        email: user.email,
        is_active: user.is_active,
        timestamp: DateTime.utc_now()
      }
      
      Deeper_Hub.Core.EventBus.publish(:user_updated, event_data)
    rescue
      _ -> :ok
    end
  end
  
  defp publish_user_deleted(user) do
    try do
      event_data = %{
        user_id: user.id,
        username: user.username,
        email: user.email,
        timestamp: DateTime.utc_now()
      }
      
      Deeper_Hub.Core.EventBus.publish(:user_deleted, event_data)
    rescue
      _ -> :ok
    end
  end
end
