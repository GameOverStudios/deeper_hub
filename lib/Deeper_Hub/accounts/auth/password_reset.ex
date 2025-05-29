defmodule DeeperHub.Accounts.Auth.PasswordReset do
  @moduledoc """
  Módulo para gerenciamento de recuperação de senha no DeeperHub.
  
  Este módulo fornece funções para solicitar, verificar e processar
  a recuperação de senha de usuários, garantindo a segurança do processo.
  
  Responsável por:
  - Geração de tokens de recuperação de senha
  - Verificação da validade dos tokens
  - Processo de redefinição de senha
  - Invalidação de tokens após uso ou expiração
  - Envio de emails de recuperação de senha
  
  Todas as operações incluem validações robustas e tratamento de erros
  para garantir a integridade dos dados e a segurança do sistema.
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
    * `{:ok, nil}` - Se o email não for encontrado (por segurança, não informamos ao cliente)
    * `{:error, :invalid_email}` - Se o email for inválido
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
    * `{:error, :email_sending_failed}` - Se ocorrer um erro ao enviar o email
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.PasswordReset.request_reset("usuario@exemplo.com")
      {:ok, "user123"}
  """
  @spec request_reset(String.t()) :: {:ok, String.t() | nil} | {:error, atom()}
  def request_reset(email) when is_binary(email) and email != "" do
    if String.contains?(email, "@") do
      try do
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
                    
                    case Mail.send_action_confirmation(
                      email,
                      user["username"],
                      "redefinição de senha",
                      reset_url,
                      nil,
                      [expires_in_hours: @expiry_hours, priority: :high]
                    ) do
                      :ok ->
                        Logger.info("Solicitação de recuperação de senha criada para usuário: #{user["id"]}", 
                          module: __MODULE__, 
                          expiry_hours: @expiry_hours
                        )
                        
                        {:ok, user["id"]}
                        
                      {:error, email_error} ->
                        Logger.error("Erro ao enviar email de recuperação de senha: #{inspect(email_error)}", 
                          module: __MODULE__, 
                          user_id: user["id"],
                          email: email
                        )
                        {:error, :email_sending_failed}
                    end
                    
                  {:error, reason} ->
                    Logger.error("Erro ao criar token de recuperação de senha: #{inspect(reason)}", 
                      module: __MODULE__, 
                      user_id: user["id"]
                    )
                    {:error, :database_error}
                end
                
              {:error, reason} ->
                Logger.error("Erro ao invalidar tokens existentes: #{inspect(reason)}", 
                  module: __MODULE__, 
                  user_id: user["id"]
                )
                {:error, :database_error}
            end
        
          {:error, :not_found} ->
            # Por segurança, não informamos se o email existe ou não
            # Simulamos um sucesso para evitar enumeração de emails
            Logger.info("Tentativa de recuperação de senha para email não cadastrado: #{email}", 
              module: __MODULE__
            )
            {:ok, nil}
            
          {:error, reason} ->
            Logger.error("Erro ao buscar usuário para recuperação de senha: #{inspect(reason)}", 
              module: __MODULE__,
              email: email
            )
            {:error, :database_error}
        end
      rescue
        e ->
          Logger.error("Erro inesperado ao processar recuperação de senha: #{Exception.message(e)}", 
            module: __MODULE__,
            email: email
          )
          {:error, :unexpected_error}
      end
    else
      Logger.warn("Tentativa de recuperação de senha com formato de email inválido: #{email}", 
        module: __MODULE__
      )
      {:error, :invalid_email}
    end
  end
  
  def request_reset(_) do
    Logger.warn("Tentativa de recuperação de senha com email inválido", module: __MODULE__)
    {:error, :invalid_email}
  end
  
  @doc """
  Verifica se um token de recuperação de senha é válido.
  
  ## Parâmetros
    * `token` - Token de recuperação
  
  ## Retorno
    * `{:ok, user_id}` - Se o token for válido
    * `{:error, :token_expired}` - Se o token estiver expirado
    * `{:error, :token_not_found}` - Se o token não for encontrado
    * `{:error, :invalid_expiry_date}` - Se a data de expiração do token for inválida
    * `{:error, :invalid_token}` - Se o token for inválido
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.PasswordReset.verify_token("abc123def456")
      {:ok, "user123"}
  """
  @spec verify_token(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def verify_token(token) when is_binary(token) and token != "" do
    try do
      # Busca o token
      case get_token(token) do
        {:ok, token_data} ->
          # Verifica se o token não expirou
          expiry = DateTime.from_iso8601(token_data["expires_at"])
          
          case expiry do
            {:ok, expiry_datetime, _} ->
              if DateTime.compare(DateTime.utc_now(), expiry_datetime) == :gt do
                # Token expirado
                Logger.warn("Tentativa de usar token de recuperação de senha expirado", 
                  module: __MODULE__,
                  user_id: token_data["user_id"]
                )
                {:error, :token_expired}
              else
                # Token válido
                Logger.info("Token de recuperação de senha validado com sucesso", 
                  module: __MODULE__,
                  user_id: token_data["user_id"]
                )
                {:ok, token_data["user_id"]}
              end
              
            _ ->
              Logger.error("Data de expiração inválida para token de recuperação de senha", 
                module: __MODULE__,
                token: token
              )
              {:error, :invalid_expiry_date}
          end
          
        {:error, :token_not_found} ->
          Logger.warn("Tentativa de usar token de recuperação de senha inexistente ou já utilizado", 
            module: __MODULE__,
            token: token
          )
          {:error, :token_not_found}
          
        {:error, reason} ->
          Logger.error("Erro ao verificar token de recuperação de senha: #{inspect(reason)}", 
            module: __MODULE__,
            token: token
          )
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao verificar token de recuperação de senha: #{Exception.message(e)}", 
          module: __MODULE__,
          token: token
        )
        {:error, :unexpected_error}
    end
  end
  
  def verify_token(_) do
    Logger.warn("Tentativa de verificar token de recuperação de senha inválido", module: __MODULE__)
    {:error, :invalid_token}
  end
  
  @doc """
  Redefine a senha de um usuário usando um token de recuperação.
  
  ## Parâmetros
    * `token` - Token de recuperação
    * `new_password` - Nova senha
  
  ## Retorno
    * `{:ok, user_id}` - Se a senha for redefinida com sucesso
    * `{:error, :invalid_token}` - Se o token for inválido
    * `{:error, :token_expired}` - Se o token estiver expirado
    * `{:error, :password_too_short}` - Se a nova senha for muito curta
    * `{:error, :password_too_weak}` - Se a nova senha não atender aos requisitos de segurança
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.PasswordReset.reset_password("abc123def456", "NovaSenha123!")
      {:ok, "user123"}
  """
  @spec reset_password(String.t(), String.t()) :: {:ok, String.t()} | {:error, atom()}
  def reset_password(token, new_password) when is_binary(token) and token != "" and is_binary(new_password) do
    try do
      # Verifica o token
      case verify_token(token) do
        {:ok, user_id} ->
          # Valida a nova senha
          case validate_password(new_password) do
            :ok ->
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
                  {:error, :database_error}
              end
              
            {:error, reason} ->
              Logger.warn("Tentativa de redefinir senha com senha inválida", 
                module: __MODULE__,
                user_id: user_id,
                reason: reason
              )
              {:error, reason}
          end
          
        {:error, reason} ->
          # O erro já foi registrado na função verify_token
          {:error, reason}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao redefinir senha: #{Exception.message(e)}", 
          module: __MODULE__,
          token: token
        )
        {:error, :unexpected_error}
    end
  end
  
  def reset_password(_, _) do
    Logger.warn("Tentativa de redefinir senha com parâmetros inválidos", module: __MODULE__)
    {:error, :invalid_input}
  end
  
  # Funções privadas
  
  # Busca um usuário pelo email
  @spec get_user_by_email(String.t()) :: {:ok, map()} | {:error, atom()}
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
        {:error, :database_error}
    end
  end
  
  # Valida a senha
  @spec validate_password(String.t()) :: :ok | {:error, atom()}
  defp validate_password(password) do
    cond do
      String.length(password) < 8 ->
        {:error, :password_too_short}
        
      not (String.match?(password, ~r/[A-Z]/) and 
           String.match?(password, ~r/[a-z]/) and 
           String.match?(password, ~r/[0-9]/) and
           String.match?(password, ~r/[^A-Za-z0-9]/)) ->
        {:error, :password_too_weak}
        
      true ->
        :ok
    end
  end
  
  # Busca um token de recuperação
  @spec get_token(String.t()) :: {:ok, map()} | {:error, atom()}
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
        {:error, :database_error}
    end
  end
  
  # Invalida todos os tokens existentes para um usuário
  @spec invalidate_existing_tokens(String.t()) :: :ok | {:error, atom()}
  defp invalidate_existing_tokens(user_id) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = """
    UPDATE password_reset_tokens
    SET used = TRUE, updated_at = ?
    WHERE user_id = ? AND used = FALSE;
    """
    
    case Repo.execute(sql, [now, user_id]) do
      {:ok, _} -> 
        Logger.debug("Tokens de recuperação de senha anteriores invalidados para usuário: #{user_id}", 
          module: __MODULE__
        )
        :ok
      {:error, reason} -> 
        Logger.error("Erro ao invalidar tokens de recuperação de senha anteriores: #{inspect(reason)}", 
          module: __MODULE__,
          user_id: user_id
        )
        {:error, :database_error}
    end
  end
  
  # Invalida um token específico
  @spec invalidate_token(String.t()) :: :ok | {:error, atom()}
  defp invalidate_token(token) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = """
    UPDATE password_reset_tokens
    SET used = TRUE, updated_at = ?
    WHERE token = ?;
    """
    
    case Repo.execute(sql, [now, token]) do
      {:ok, %{rows_affected: 1}} -> 
        Logger.debug("Token de recuperação de senha invalidado: #{token}", module: __MODULE__)
        :ok
      {:ok, %{rows_affected: 0}} -> 
        Logger.warn("Tentativa de invalidar token de recuperação de senha inexistente: #{token}", module: __MODULE__)
        {:error, :token_not_found}
      {:error, reason} -> 
        Logger.error("Erro ao invalidar token de recuperação de senha: #{inspect(reason)}", 
          module: __MODULE__,
          token: token
        )
        {:error, :database_error}
    end
  end
  
  # Gera um token de recuperação
  @spec generate_reset_token() :: String.t()
  defp generate_reset_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
