defmodule DeeperHub.Accounts.Permission do
  @moduledoc """
  Módulo para gerenciamento de permissões e papéis de usuário no DeeperHub.
  
  Este módulo fornece funções para definir e verificar permissões de usuários,
  atribuir papéis (roles) e controlar o acesso a recursos do sistema.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  # Papéis de usuário disponíveis
  @roles %{
    admin: "admin",
    moderator: "moderator",
    user: "user"
  }
  
  # Permissões disponíveis por papel
  @role_permissions %{
    "admin" => [
      "user:read", "user:write", "user:delete",
      "content:read", "content:write", "content:delete",
      "system:read", "system:write", "system:delete"
    ],
    "moderator" => [
      "user:read",
      "content:read", "content:write", "content:delete"
    ],
    "user" => [
      "user:read",
      "content:read", "content:write"
    ]
  }
  
  @doc """
  Atribui um papel a um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `role` - Papel a ser atribuído (atom)
  
  ## Retorno
    * `:ok` - Se o papel for atribuído com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def assign_role(user_id, role) do
    # Valida o papel
    role_str = Map.get(@roles, role)
    
    if role_str do
      # Verifica se o usuário já tem um papel atribuído
      case get_user_role(user_id) do
        {:ok, _existing_role} ->
          # Atualiza o papel existente
          update_user_role(user_id, role_str)
          
        {:error, :not_found} ->
          # Insere um novo papel
          insert_user_role(user_id, role_str)
          
        {:error, reason} ->
          {:error, reason}
      end
    else
      Logger.error("Papel inválido: #{inspect(role)}", 
        module: __MODULE__, 
        user_id: user_id
      )
      {:error, :invalid_role}
    end
  end
  
  @doc """
  Obtém o papel de um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
  
  ## Retorno
    * `{:ok, role}` - Papel do usuário (string)
    * `{:error, reason}` - Se ocorrer um erro
  """
  def get_user_role(user_id) do
    sql = "SELECT role FROM user_roles WHERE user_id = ?;"
    
    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: [[role]]}} ->
        {:ok, role}
        
      {:ok, %{rows: []}} ->
        {:error, :not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar papel do usuário: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
        {:error, reason}
    end
  end
  
  @doc """
  Verifica se um usuário tem uma permissão específica.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `permission` - Permissão a ser verificada (string)
  
  ## Retorno
    * `{:ok, true}` - Se o usuário tem a permissão
    * `{:ok, false}` - Se o usuário não tem a permissão
    * `{:error, reason}` - Se ocorrer um erro
  """
  def has_permission?(user_id, permission) do
    case get_user_role(user_id) do
      {:ok, role} ->
        # Obtém as permissões do papel
        permissions = Map.get(@role_permissions, role, [])
        
        # Verifica se a permissão está na lista
        {:ok, permission in permissions}
        
      {:error, :not_found} ->
        # Se o usuário não tem papel atribuído, assume que não tem permissão
        {:ok, false}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Verifica se um usuário tem um papel específico.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `role` - Papel a ser verificado (atom)
  
  ## Retorno
    * `{:ok, true}` - Se o usuário tem o papel
    * `{:ok, false}` - Se o usuário não tem o papel
    * `{:error, reason}` - Se ocorrer um erro
  """
  def has_role?(user_id, role) do
    # Valida o papel
    role_str = Map.get(@roles, role)
    
    if role_str do
      case get_user_role(user_id) do
        {:ok, user_role} ->
          {:ok, user_role == role_str}
          
        {:error, :not_found} ->
          # Se o usuário não tem papel atribuído, assume que não tem o papel
          {:ok, false}
          
        {:error, reason} ->
          {:error, reason}
      end
    else
      Logger.error("Papel inválido: #{inspect(role)}", 
        module: __MODULE__, 
        user_id: user_id
      )
      {:error, :invalid_role}
    end
  end
  
  @doc """
  Lista todos os usuários com um papel específico.
  
  ## Parâmetros
    * `role` - Papel a ser buscado (atom)
  
  ## Retorno
    * `{:ok, users}` - Lista de IDs de usuários com o papel
    * `{:error, reason}` - Se ocorrer um erro
  """
  def list_users_by_role(role) do
    # Valida o papel
    role_str = Map.get(@roles, role)
    
    if role_str do
      sql = "SELECT user_id FROM user_roles WHERE role = ?;"
      
      case Repo.query(sql, [role_str]) do
        {:ok, %{rows: rows}} ->
          # Extrai os IDs de usuário
          user_ids = Enum.map(rows, fn [user_id] -> user_id end)
          {:ok, user_ids}
          
        {:error, reason} ->
          Logger.error("Erro ao listar usuários por papel: #{inspect(reason)}", 
            module: __MODULE__, 
            role: role_str
          )
          {:error, reason}
      end
    else
      Logger.error("Papel inválido: #{inspect(role)}", 
        module: __MODULE__
      )
      {:error, :invalid_role}
    end
  end
  
  @doc """
  Obtém todos os papéis disponíveis.
  
  ## Retorno
    * Mapa com os papéis disponíveis
  """
  def get_available_roles do
    @roles
  end
  
  @doc """
  Obtém todas as permissões disponíveis para um papel.
  
  ## Parâmetros
    * `role` - Papel (atom)
  
  ## Retorno
    * `{:ok, permissions}` - Lista de permissões
    * `{:error, :invalid_role}` - Se o papel for inválido
  """
  def get_role_permissions(role) do
    # Valida o papel
    role_str = Map.get(@roles, role)
    
    if role_str do
      {:ok, Map.get(@role_permissions, role_str, [])}
    else
      {:error, :invalid_role}
    end
  end
  
  # Funções privadas
  
  # Insere um novo papel para um usuário
  defp insert_user_role(user_id, role) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = """
    INSERT INTO user_roles (user_id, role, created_at, updated_at)
    VALUES (?, ?, ?, ?);
    """
    
    case Repo.execute(sql, [user_id, role, now, now]) do
      {:ok, _} ->
        Logger.info("Papel atribuído ao usuário: #{user_id}, papel: #{role}", 
          module: __MODULE__
        )
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao inserir papel do usuário: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id, 
          role: role
        )
        {:error, reason}
    end
  end
  
  # Atualiza o papel de um usuário
  defp update_user_role(user_id, role) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = "UPDATE user_roles SET role = ?, updated_at = ? WHERE user_id = ?;"
    
    case Repo.execute(sql, [role, now, user_id]) do
      {:ok, _} ->
        Logger.info("Papel atualizado para usuário: #{user_id}, novo papel: #{role}", 
          module: __MODULE__
        )
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao atualizar papel do usuário: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id, 
          role: role
        )
        {:error, reason}
    end
  end
end
