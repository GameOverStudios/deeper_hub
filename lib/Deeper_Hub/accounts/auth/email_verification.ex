defmodule DeeperHub.Accounts.Auth.EmailVerification do
  @moduledoc """
  Módulo para gerenciamento de verificação de e-mail no DeeperHub.
  
  Este módulo fornece funções para gerar e verificar tokens de verificação
  de e-mail, permitindo confirmar a identidade dos usuários durante o
  processo de registro ou alteração de e-mail.
  
  A verificação de e-mail é uma etapa crucial para garantir a segurança e
  autenticidade das contas de usuário, reduzindo o risco de contas falsas
  e permitindo uma comunicação confiável com os usuários.
  
  O fluxo típico de verificação de e-mail é:
  1. Usuário se registra ou altera seu e-mail
  2. Sistema gera um token único e envia por e-mail
  3. Usuário clica no link contendo o token
  4. Sistema verifica o token e marca o e-mail como verificado
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.ActivityLog
  alias DeeperHub.Accounts.Mailer
  alias DeeperHub.Accounts.User
  require DeeperHub.Core.Logger
  
  # Tempo de expiração do token de verificação (em segundos)
  @token_expiration 24 * 60 * 60  # 24 horas
  
  @doc """
  Inicia o processo de verificação de e-mail para um usuário.
  
  Gera um token único, armazena-o no banco de dados e envia um e-mail
  de verificação para o usuário com um link contendo o token.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `email` - E-mail a ser verificado
    * `ip_address` - Endereço IP do cliente (opcional)
  
  ## Retorno
    * `{:ok, token}` - Se o processo for iniciado com sucesso
    * `{:error, :invalid_input}` - Se os parâmetros forem inválidos
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
    * `{:error, :email_sending_failed}` - Se ocorrer um erro ao enviar o e-mail
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.EmailVerification.request_verification("user123", "usuario@exemplo.com")
      {:ok, "abc123def456"}
  """
  @spec request_verification(String.t(), String.t(), String.t() | nil) :: {:ok, String.t()} | {:error, atom()}
  def request_verification(user_id, email, ip_address \\ nil)
  def request_verification(user_id, email, ip_address) when is_binary(user_id) and is_binary(email) do
    # Validação básica de e-mail
    if String.length(email) == 0 or not String.contains?(email, "@") do
      Logger.warn("Tentativa de verificação com e-mail inválido", 
        module: __MODULE__, 
        user_id: user_id,
        email: email
      )
      {:error, :invalid_input}
    else
      try do
        # Gera um token único
        token = generate_verification_token()
        
        # Calcula a data de expiração
        expires_at = DateTime.utc_now()
                    |> DateTime.add(@token_expiration, :second)
                    |> DateTime.to_iso8601()
        
        # Armazena o token no banco de dados
        sql = """
        INSERT INTO email_verifications (
          user_id, email, token, expires_at, created_at
        ) VALUES (?, ?, ?, ?, ?);
        """
        
        now = DateTime.utc_now() |> DateTime.to_iso8601()
        
        case Repo.execute(sql, [user_id, email, token, expires_at, now]) do
          {:ok, _} ->
            # Envia o e-mail de verificação
            case send_verification_email(user_id, email, token) do
              :ok ->
                # Registra a atividade
                ActivityLog.log_activity(user_id, :email_verification_requested, %{
                  email: email
                }, ip_address)
                
                Logger.info("Verificação de e-mail solicitada para usuário: #{user_id}", 
                  module: __MODULE__, 
                  email: email
                )
                
                {:ok, token}
                
              {:error, _reason} ->
                Logger.error("Erro ao enviar e-mail de verificação", 
                  module: __MODULE__, 
                  user_id: user_id,
                  email: email
                )
                
                {:error, :email_sending_failed}
            end
            
          {:error, reason} ->
            Logger.error("Erro ao solicitar verificação de e-mail: #{inspect(reason)}", 
              module: __MODULE__, 
              user_id: user_id,
              email: email
            )
            
            {:error, :database_error}
        end
      rescue
        e ->
          Logger.error("Erro inesperado ao solicitar verificação de e-mail: #{Exception.message(e)}", 
            module: __MODULE__, 
            user_id: user_id,
            email: email
          )
          
          {:error, :unexpected_error}
      end
    end
  end
  
  def request_verification(_, _, _) do
    Logger.error("Tentativa de solicitar verificação de e-mail com parâmetros inválidos", module: __MODULE__)
    {:error, :invalid_input}
  end
  
  @doc """
  Verifica um token de verificação de e-mail.
  
  Busca o token no banco de dados, verifica se é válido e não expirou,
  e marca o e-mail como verificado se o token for válido.
  
  ## Parâmetros
    * `token` - Token de verificação
    * `ip_address` - Endereço IP do cliente (opcional)
  
  ## Retorno
    * `{:ok, user_id, email}` - Se o token for válido e o e-mail for marcado como verificado
    * `{:error, :invalid_input}` - Se o token for inválido
    * `{:error, :token_expired}` - Se o token expirou
    * `{:error, :token_not_found}` - Se o token não for encontrado ou já foi utilizado
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
    * `{:error, :invalid_timestamp}` - Se a data de expiração for inválida
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.EmailVerification.verify_token("abc123def456")
      {:ok, "user123", "usuario@exemplo.com"}
  """
  @spec verify_token(String.t(), String.t() | nil) :: {:ok, String.t(), String.t()} | {:error, atom()}
  def verify_token(token, ip_address \\ nil)
  def verify_token(token, ip_address) when is_binary(token) and token != "" do
    try do
      # Busca o token no banco de dados
      sql = """
      SELECT user_id, email, expires_at
      FROM email_verifications
      WHERE token = ? AND verified_at IS NULL AND invalidated_at IS NULL;
      """
      
      case Repo.query(sql, [token]) do
        {:ok, %{rows: [[user_id, email, expires_at]]}} ->
          # Verifica se o token expirou
          case DateTime.from_iso8601(expires_at) do
            {:ok, expires_at_dt, _} ->
              if DateTime.compare(DateTime.utc_now(), expires_at_dt) == :gt do
                # Token expirado
                Logger.info("Tentativa de verificação com token expirado", 
                  module: __MODULE__, 
                  token: token,
                  user_id: user_id,
                  email: email
                )
                
                # Invalida o token expirado
                invalidate_token(token, "expired")
                
                {:error, :token_expired}
              else
                # Token válido, marca como verificado
                mark_as_verified(token, user_id, email, ip_address)
              end
              
            _ ->
              # Erro ao parsear a data de expiração
              Logger.error("Erro ao parsear data de expiração do token", 
                module: __MODULE__, 
                token: token,
                expires_at: expires_at
              )
              
              {:error, :invalid_timestamp}
          end
          
        {:ok, %{rows: []}} ->
          # Token não encontrado ou já utilizado
          Logger.info("Tentativa de verificação com token não encontrado ou já utilizado", 
            module: __MODULE__, 
            token: token
          )
          
          {:error, :token_not_found}
          
        {:error, reason} ->
          Logger.error("Erro ao verificar token de e-mail: #{inspect(reason)}", 
            module: __MODULE__, 
            token: token
          )
          
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao verificar token de e-mail: #{Exception.message(e)}", 
          module: __MODULE__, 
          token: token
        )
        
        {:error, :unexpected_error}
    end
  end
  
  def verify_token(_, _) do
    Logger.warn("Tentativa de verificar token inválido", module: __MODULE__)
    {:error, :invalid_input}
  end
  
  # Função privada para invalidar um token de verificação
  @spec invalidate_token(String.t(), String.t()) :: :ok | {:error, atom()}
  defp invalidate_token(token, reason) when is_binary(token) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    sql = """
    UPDATE email_verifications
    SET invalidated_at = ?, invalidation_reason = ?
    WHERE token = ? AND verified_at IS NULL AND invalidated_at IS NULL;
    """
    
    case Repo.execute(sql, [now, reason, token]) do
      {:ok, _} ->
        Logger.info("Token de verificação invalidado: #{token}", 
          module: __MODULE__, 
          reason: reason
        )
        
        :ok
        
      {:error, db_reason} ->
        Logger.error("Erro ao invalidar token de verificação: #{inspect(db_reason)}", 
          module: __MODULE__, 
          token: token
        )
        
        {:error, :database_error}
    end
  end
  
  @doc """
  Marca um e-mail como verificado.
  
  Atualiza o registro de verificação e o status do usuário no banco de dados,
  registrando a atividade de verificação bem-sucedida.
  
  ## Parâmetros
    * `token` - Token de verificação
    * `user_id` - ID do usuário
    * `email` - E-mail verificado
    * `ip_address` - Endereço IP do cliente (opcional)
  
  ## Retorno
    * `{:ok, user_id, email}` - Se o e-mail for marcado como verificado
    * `{:error, :invalid_input}` - Se os parâmetros forem inválidos
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
    * `{:error, :user_not_found}` - Se o usuário não for encontrado
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.EmailVerification.mark_as_verified("abc123def456", "user123", "usuario@exemplo.com")
      {:ok, "user123", "usuario@exemplo.com"}
  """
  @spec mark_as_verified(String.t(), String.t(), String.t(), String.t() | nil) :: {:ok, String.t(), String.t()} | {:error, atom()}
  def mark_as_verified(token, user_id, email, ip_address \\ nil)
  def mark_as_verified(token, user_id, email, ip_address) 
      when is_binary(token) and is_binary(user_id) and is_binary(email) do
    try do
      # Verifica se o usuário existe
      case User.get(user_id) do
        {:ok, _user} ->
          # Atualiza o registro de verificação
          now = DateTime.utc_now() |> DateTime.to_iso8601()
          
          # Inicia uma transação para garantir consistência
          Repo.transaction(fn ->
            # 1. Atualiza o registro de verificação
            update_sql = """
            UPDATE email_verifications
            SET verified_at = ?
            WHERE token = ? AND verified_at IS NULL AND invalidated_at IS NULL;
            """
            
            case Repo.execute(update_sql, [now, token]) do
              {:ok, %{rows_affected: 1}} ->
                # 2. Atualiza o status de verificação do usuário
                update_user_sql = """
                UPDATE users
                SET email_verified = TRUE, updated_at = ?
                WHERE id = ? AND email = ?;
                """
                
                case Repo.execute(update_user_sql, [now, user_id, email]) do
                  {:ok, %{rows_affected: 1}} ->
                    # 3. Registra a atividade
                    ActivityLog.log_activity(user_id, :email_verified, %{
                      email: email
                    }, ip_address)
                    
                    Logger.info("E-mail verificado com sucesso: #{email}", 
                      module: __MODULE__, 
                      user_id: user_id
                    )
                    
                    {:ok, user_id, email}
                    
                  {:ok, %{rows_affected: 0}} ->
                    Logger.warn("Usuário ou e-mail não encontrado ao atualizar status de verificação", 
                      module: __MODULE__, 
                      user_id: user_id,
                      email: email
                    )
                    
                    {:error, :user_not_found}
                    
                  {:error, reason} ->
                    Logger.error("Erro ao atualizar status de verificação do usuário: #{inspect(reason)}", 
                      module: __MODULE__, 
                      user_id: user_id,
                      email: email
                    )
                    
                    {:error, :database_error}
                end
                
              {:ok, %{rows_affected: 0}} ->
                Logger.warn("Token não encontrado ou já utilizado ao marcar como verificado", 
                  module: __MODULE__, 
                  token: token
                )
                
                {:error, :token_not_found}
                
              {:error, reason} ->
                Logger.error("Erro ao marcar e-mail como verificado: #{inspect(reason)}", 
                  module: __MODULE__, 
                  token: token
                )
                
                {:error, :database_error}
            end
          end)
          
        {:error, :not_found} ->
          Logger.warn("Tentativa de verificar e-mail para usuário inexistente", 
            module: __MODULE__, 
            user_id: user_id,
            email: email
          )
          
          {:error, :user_not_found}
          
        {:error, reason} ->
          Logger.error("Erro ao buscar usuário para verificação de e-mail: #{inspect(reason)}", 
            module: __MODULE__, 
            user_id: user_id
          )
          
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao marcar e-mail como verificado: #{Exception.message(e)}", 
          module: __MODULE__, 
          token: token,
          user_id: user_id,
          email: email
        )
        
        {:error, :unexpected_error}
    end
  end
  
  def mark_as_verified(_, _, _, _) do
    Logger.warn("Tentativa de marcar e-mail como verificado com parâmetros inválidos", module: __MODULE__)
    {:error, :invalid_input}
  end
  
  @doc """
  Reenvia o e-mail de verificação.
  
  Invalida todos os tokens anteriores não utilizados e gera um novo token,
  enviando um novo e-mail de verificação para o usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `email` - E-mail a ser verificado
    * `ip_address` - Endereço IP do cliente (opcional)
  
  ## Retorno
    * `{:ok, token}` - Se o e-mail for reenviado com sucesso
    * `{:error, :invalid_input}` - Se os parâmetros forem inválidos
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
    * `{:error, :email_sending_failed}` - Se ocorrer um erro ao enviar o e-mail
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.EmailVerification.resend_verification("user123", "usuario@exemplo.com")
      {:ok, "abc123def456"}
  """
  @spec resend_verification(String.t(), String.t(), String.t() | nil) :: {:ok, String.t()} | {:error, atom()}
  def resend_verification(user_id, email, ip_address \\ nil)
  def resend_verification(user_id, email, ip_address) when is_binary(user_id) and is_binary(email) do
    try do
      # Invalida tokens anteriores
      invalidate_sql = """
      UPDATE email_verifications
      SET invalidated_at = ?, invalidation_reason = ?
      WHERE user_id = ? AND email = ? AND verified_at IS NULL AND invalidated_at IS NULL;
      """
      
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      
      case Repo.execute(invalidate_sql, [now, "resent", user_id, email]) do
        {:ok, _} ->
          # Registra a atividade de reenvio
          ActivityLog.log_activity(user_id, :email_verification_resent, %{
            email: email
          }, ip_address)
          
          Logger.info("Tokens anteriores invalidados, reenviando verificação para: #{email}", 
            module: __MODULE__, 
            user_id: user_id
          )
          
          # Solicita nova verificação
          request_verification(user_id, email, ip_address)
          
        {:error, reason} ->
          Logger.error("Erro ao invalidar tokens anteriores: #{inspect(reason)}", 
            module: __MODULE__, 
            user_id: user_id,
            email: email
          )
          
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao reenviar verificação de e-mail: #{Exception.message(e)}", 
          module: __MODULE__, 
          user_id: user_id,
          email: email
        )
        
        {:error, :unexpected_error}
    end
  end
  
  def resend_verification(_, _, _) do
    Logger.warn("Tentativa de reenviar verificação com parâmetros inválidos", module: __MODULE__)
    {:error, :invalid_input}
  end
  
  @doc """
  Verifica se um e-mail já foi verificado para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `email` - E-mail a ser verificado
  
  ## Retorno
    * `{:ok, true}` - Se o e-mail já foi verificado
    * `{:ok, false}` - Se o e-mail ainda não foi verificado
    * `{:error, :invalid_input}` - Se os parâmetros forem inválidos
    * `{:error, :user_not_found}` - Se o usuário não for encontrado
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.EmailVerification.is_verified?("user123", "usuario@exemplo.com")
      {:ok, true}
  """
  @spec is_verified?(String.t(), String.t()) :: {:ok, boolean()} | {:error, atom()}
  def is_verified?(user_id, email) when is_binary(user_id) and is_binary(email) do
    try do
      sql = """
      SELECT email_verified
      FROM users
      WHERE id = ? AND email = ?;
      """
      
      case Repo.query(sql, [user_id, email]) do
        {:ok, %{rows: [[verified]]}} ->
          Logger.debug("Status de verificação de e-mail consultado: #{verified}", 
            module: __MODULE__, 
            user_id: user_id,
            email: email
          )
          
          {:ok, verified}
          
        {:ok, %{rows: []}} ->
          # Usuário ou e-mail não encontrado
          Logger.warn("Usuário ou e-mail não encontrado ao verificar status", 
            module: __MODULE__, 
            user_id: user_id,
            email: email
          )
          
          {:error, :user_not_found}
          
        {:error, reason} ->
          Logger.error("Erro ao verificar status de e-mail: #{inspect(reason)}", 
            module: __MODULE__, 
            user_id: user_id,
            email: email
          )
          
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao verificar status de e-mail: #{Exception.message(e)}", 
          module: __MODULE__, 
          user_id: user_id,
          email: email
        )
        
        {:error, :unexpected_error}
    end
  end
  
  def is_verified?(_, _) do
    Logger.warn("Tentativa de verificar status de e-mail com parâmetros inválidos", module: __MODULE__)
    {:error, :invalid_input}
  end
  
  @doc """
  Limpa tokens de verificação expirados ou utilizados.
  
  Esta função deve ser chamada periodicamente para evitar o crescimento
  excessivo da tabela de tokens de verificação de e-mail.
  
  ## Retorno
    * `{:ok, count}` - Número de tokens removidos
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.EmailVerification.clean_tokens()
      {:ok, 25}
  """
  @spec clean_tokens() :: {:ok, integer()} | {:error, atom()}
  def clean_tokens do
    try do
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      
      # Remove tokens expirados ou já verificados com mais de 30 dias
      sql = """
      DELETE FROM email_verifications
      WHERE (expires_at < ? AND verified_at IS NULL)
         OR (verified_at IS NOT NULL AND verified_at < datetime(?, '-30 days'))
         OR (invalidated_at IS NOT NULL AND invalidated_at < datetime(?, '-30 days'));
      """
      
      case Repo.execute(sql, [now, now, now]) do
        {:ok, %{rows_affected: count}} ->
          Logger.info("Tokens de verificação de e-mail removidos: #{count}", module: __MODULE__)
          {:ok, count}
          
        {:error, reason} ->
          Logger.error("Erro ao limpar tokens de verificação de e-mail: #{inspect(reason)}", module: __MODULE__)
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao limpar tokens de verificação: #{Exception.message(e)}", module: __MODULE__)
        {:error, :unexpected_error}
    end
  end
  
  @doc false
  # Gera um token de verificação único
  @spec generate_verification_token() :: String.t()
  defp generate_verification_token do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)
  end
  
  @doc false
  # Envia o e-mail de verificação
  @spec send_verification_email(String.t(), String.t(), String.t()) :: :ok | {:error, atom()}
  defp send_verification_email(user_id, email, token) do
    try do
      # Busca informações do usuário
      case User.get(user_id) do
        {:ok, user} ->
          # Constrói o link de verificação
          base_url = Application.get_env(:deeper_hub, :base_url, "http://localhost:8080")
          verification_url = "#{base_url}/verify-email?token=#{token}"
          
          # Prepara o e-mail
          subject = "Verificação de E-mail - DeeperHub"
          
          # Obtém o nome do usuário ou usa um valor padrão
          name = Map.get(user, "name") || Map.get(user, "username") || "Usuário"
          
          body = """
          Olá #{name},
          
          Por favor, verifique seu e-mail clicando no link abaixo:
          
          #{verification_url}
          
          Este link expirará em 24 horas.
          
          Se você não solicitou esta verificação, por favor ignore este e-mail.
          
          Atenciosamente,
          Equipe DeeperHub
          """
          
          # Envia o e-mail
          case Mailer.send_email(email, subject, body) do
            :ok -> 
              Logger.info("E-mail de verificação enviado com sucesso", 
                module: __MODULE__, 
                user_id: user_id,
                email: email
              )
              :ok
              
            {:error, reason} -> 
              Logger.error("Erro ao enviar e-mail de verificação: #{inspect(reason)}", 
                module: __MODULE__, 
                user_id: user_id,
                email: email
              )
              {:error, :email_sending_failed}
          end
          
        {:error, :not_found} ->
          Logger.error("Usuário não encontrado ao enviar e-mail de verificação", 
            module: __MODULE__, 
            user_id: user_id
          )
          {:error, :user_not_found}
          
        {:error, reason} ->
          Logger.error("Erro ao buscar informações do usuário para envio de e-mail: #{inspect(reason)}", 
            module: __MODULE__, 
            user_id: user_id
          )
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao enviar e-mail de verificação: #{Exception.message(e)}", 
          module: __MODULE__, 
          user_id: user_id,
          email: email
        )
        {:error, :unexpected_error}
    end
  end
  
  @doc """
  Obtém estatísticas sobre os tokens de verificação de e-mail.
  
  ## Retorno
    * `{:ok, stats}` - Mapa contendo as estatísticas
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.EmailVerification.get_stats()
      {:ok, %{total: 100, verified: 75, pending: 20, expired: 5}}
  """
  @spec get_stats() :: {:ok, map()} | {:error, atom()}
  def get_stats do
    try do
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      
      sql = """
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN verified_at IS NOT NULL THEN 1 ELSE 0 END) as verified,
        SUM(CASE WHEN verified_at IS NULL AND invalidated_at IS NULL AND expires_at >= ? THEN 1 ELSE 0 END) as pending,
        SUM(CASE WHEN verified_at IS NULL AND invalidated_at IS NULL AND expires_at < ? THEN 1 ELSE 0 END) as expired,
        SUM(CASE WHEN invalidated_at IS NOT NULL THEN 1 ELSE 0 END) as invalidated
      FROM email_verifications;
      """
      
      case Repo.query(sql, [now, now]) do
        {:ok, %{rows: [[total, verified, pending, expired, invalidated]], columns: ["total", "verified", "pending", "expired", "invalidated"]}} ->
          stats = %{
            total: total,
            verified: verified,
            pending: pending,
            expired: expired,
            invalidated: invalidated
          }
          
          Logger.info("Estatísticas de verificação de e-mail: total=#{total}, verificados=#{verified}, pendentes=#{pending}, expirados=#{expired}", 
            module: __MODULE__
          )
          
          {:ok, stats}
          
        {:error, reason} ->
          Logger.error("Erro ao obter estatísticas de verificação de e-mail: #{inspect(reason)}", module: __MODULE__)
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao obter estatísticas de verificação de e-mail: #{Exception.message(e)}", module: __MODULE__)
        {:error, :unexpected_error}
    end
  end
end
