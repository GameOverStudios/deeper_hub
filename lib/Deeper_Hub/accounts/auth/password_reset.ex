defmodule DeeperHub.Accounts.Auth.PasswordReset do
  @moduledoc """
  Módulo para gerenciamento de recuperação de senha no DeeperHub.
  
  Este módulo fornece funções para solicitar, verificar e processar
  a recuperação de senha de usuários, garantindo a segurança do processo.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Mail
  alias DeeperHub.Accounts.User
  alias DeeperHub.Accounts.Auth.Token
  alias DeeperHub.Accounts.ActivityLog
  require DeeperHub.Core.Logger
  
  # Tempo de expiração do token de recuperação em horas
  @expiry_hours 24
  
  @doc """
  Solicita a recuperação de senha para um usuário.
  
  ## Parâmetros
    * `email` - Email do usuário
  
  ## Retorno
    * `{:ok, user_id}` - Se a solicitação for criada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def request_reset(email) do
    # Busca o usuário pelo email
    case get_user_by_email(email) do
      {:ok, user} ->
        # Gera um token de recuperação
        reset_token = generate_reset_token()
        
        # Calcula a data de expiração
        expiry = DateTime.utc_now() |> DateTime.add(@expiry_hours * 3600, :second) |> DateTime.to_iso8601()
        now = DateTime.utc_now() |> DateTime.to_iso8601()
        
        sql = """
        INSERT INTO password_reset_tokens 
        (user_id, token, expires_at, created_at)
        VALUES (?, ?, ?, ?);
        """
        
        params = [
          user["id"],
          reset_token,
          expiry,
          now
        ]
        
        # Primeiro verifica se já existe um token válido
        case invalidate_existing_tokens(user["id"]) do
          :ok ->
            # Cria o token
            case Repo.execute(sql, params) do
              {:ok, _} ->
                # Registra a atividade
                ActivityLog.log_activity(user["id"], :password_reset_requested)
                
                # Envia email com o link de recuperação
                reset_url = "https://deeperhub.com/redefinir-senha?token=#{reset_token}"
                
                Mail.send_action_confirmation(
                  email,
                  user["username"],
                  "redefinição de senha",
                  reset_url,
                  nil,
                  [expires_in_hours: @expiry_hours, priority: :high]
                )
                
                Logger.info("Solicitação de recuperação de senha criada para usuário: #{user["id"]}", 
                  module: __MODULE__, 
                  expiry_hours: @expiry_hours
                )
                
                {:ok, user["id"]}
                
              {:error, reason} ->
                Logger.error("Erro ao criar token de recuperação de senha: #{inspect(reason)}", 
                  module: __MODULE__, 
                  user_id: user["id"]
                )
                {:error, reason}
            end
            
          {:error, reason} ->
            {:error, reason}
        end
        
      {:error, :not_found} ->
        # Por segurança, não informamos se o email existe ou não
        # Simulamos um sucesso para evitar enumeração de emails
        Logger.info("Tentativa de recuperação de senha para email não cadastrado: #{email}", 
          module: __MODULE__
        )
        {:ok, nil}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Verifica se um token de recuperação de senha é válido.
  
  ## Parâmetros
    * `token` - Token de recuperação
  
  ## Retorno
    * `{:ok, user_id}` - Se o token for válido
    * `{:error, reason}` - Se o token for inválido
  """
  def verify_token(token) do
    # Busca o token
    case get_token(token) do
      {:ok, token_data} ->
        # Verifica se o token não expirou
        expiry = DateTime.from_iso8601(token_data["expires_at"])
        
        case expiry do
          {:ok, expiry_datetime, _} ->
            if DateTime.compare(DateTime.utc_now(), expiry_datetime) == :gt do
              # Token expirado
              {:error, :token_expired}
            else
              # Token válido
              {:ok, token_data["user_id"]}
            end
            
          _ ->
            {:error, :invalid_expiry_date}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Redefine a senha de um usuário usando um token de recuperação.
  
  ## Parâmetros
    * `token` - Token de recuperação
    * `new_password` - Nova senha
  
  ## Retorno
    * `{:ok, user_id}` - Se a senha for redefinida com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def reset_password(token, new_password) do
    # Verifica o token
    case verify_token(token) do
      {:ok, user_id} ->
        # Atualiza a senha
        case User.update(user_id, %{password: new_password}) do
          {:ok, _} ->
            # Invalida o token usado
            invalidate_token(token)
            
            # Revoga todos os tokens de acesso do usuário
            Token.revoke_all_for_user(user_id)
            
            # Registra a atividade
            ActivityLog.log_activity(user_id, :password_reset_completed)
            
            Logger.info("Senha redefinida com sucesso para usuário: #{user_id}", 
              module: __MODULE__
            )
            
            {:ok, user_id}
            
          {:error, reason} ->
            Logger.error("Erro ao redefinir senha: #{inspect(reason)}", 
              module: __MODULE__, 
              user_id: user_id
            )
            {:error, reason}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Funções privadas
  
  # Busca um usuário pelo email
  defp get_user_by_email(email) do
    sql = "SELECT id, username, email FROM users WHERE email = ? AND status = 'active';"
    
    case Repo.query(sql, [email]) do
      {:ok, %{rows: [row], columns: columns}} ->
        user = Enum.zip(columns, row) |> Map.new()
        {:ok, user}
        
      {:ok, %{rows: []}} ->
        {:error, :not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar usuário por email: #{inspect(reason)}", 
          module: __MODULE__, 
          email: email
        )
        {:error, reason}
    end
  end
  
  # Busca um token de recuperação
  defp get_token(token) do
    sql = """
    SELECT user_id, token, expires_at, created_at
    FROM password_reset_tokens
    WHERE token = ? AND used = FALSE;
    """
    
    case Repo.query(sql, [token]) do
      {:ok, %{rows: [row], columns: columns}} ->
        token_data = Enum.zip(columns, row) |> Map.new()
        {:ok, token_data}
        
      {:ok, %{rows: []}} ->
        {:error, :token_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar token de recuperação: #{inspect(reason)}", 
          module: __MODULE__, 
          token: token
        )
        {:error, reason}
    end
  end
  
  # Invalida todos os tokens existentes para um usuário
  defp invalidate_existing_tokens(user_id) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = """
    UPDATE password_reset_tokens
    SET used = TRUE, updated_at = ?
    WHERE user_id = ? AND used = FALSE;
    """
    
    case Repo.execute(sql, [now, user_id]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Invalida um token específico
  defp invalidate_token(token) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = """
    UPDATE password_reset_tokens
    SET used = TRUE, updated_at = ?
    WHERE token = ?;
    """
    
    case Repo.execute(sql, [now, token]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Gera um token de recuperação
  defp generate_reset_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
