defmodule DeeperHub.Accounts.Auth.EmailVerification do
  @moduledoc """
  Módulo para gerenciamento de verificação de e-mail no DeeperHub.
  
  Este módulo fornece funções para gerar e verificar tokens de verificação
  de e-mail, permitindo confirmar a identidade dos usuários durante o
  processo de registro ou alteração de e-mail.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.ActivityLog
  alias DeeperHub.Accounts.User
  alias DeeperHub.Accounts.Mailer
  require DeeperHub.Core.Logger
  
  # Tempo de expiração do token de verificação (em segundos)
  @token_expiration 24 * 60 * 60  # 24 horas
  
  @doc """
  Inicia o processo de verificação de e-mail para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `email` - E-mail a ser verificado
    * `ip_address` - Endereço IP do cliente (opcional)
  
  ## Retorno
    * `{:ok, token}` - Se o processo for iniciado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec request_verification(String.t(), String.t(), String.t() | nil) :: {:ok, String.t()} | {:error, any()}
  def request_verification(user_id, email, ip_address \\ nil) do
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
        send_verification_email(user_id, email, token)
        
        # Registra a atividade
        ActivityLog.log_activity(user_id, :email_verification_requested, %{
          email: email
        }, ip_address)
        
        Logger.info("Verificação de e-mail solicitada para usuário: #{user_id}", 
          module: __MODULE__, 
          email: email
        )
        
        {:ok, token}
        
      {:error, reason} ->
        Logger.error("Erro ao solicitar verificação de e-mail: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id,
          email: email
        )
        
        {:error, reason}
    end
  end
  
  @doc """
  Verifica um token de verificação de e-mail.
  
  ## Parâmetros
    * `token` - Token de verificação
    * `ip_address` - Endereço IP do cliente (opcional)
  
  ## Retorno
    * `{:ok, user_id, email}` - Se o token for válido
    * `{:error, :token_expired}` - Se o token expirou
    * `{:error, :token_not_found}` - Se o token não for encontrado
    * `{:error, reason}` - Se ocorrer outro erro
  """
  @spec verify_token(String.t(), String.t() | nil) :: {:ok, String.t(), String.t()} | {:error, any()}
  def verify_token(token, ip_address \\ nil) do
    # Busca o token no banco de dados
    sql = """
    SELECT user_id, email, expires_at
    FROM email_verifications
    WHERE token = ? AND verified_at IS NULL;
    """
    
    case Repo.query(sql, [token]) do
      {:ok, %{rows: [[user_id, email, expires_at]]}} ->
        # Verifica se o token expirou
        case DateTime.from_iso8601(expires_at) do
          {:ok, expires_at_dt, _} ->
            if DateTime.compare(DateTime.utc_now(), expires_at_dt) == :gt do
              # Token expirado
              {:error, :token_expired}
            else
              # Token válido, marca como verificado
              mark_as_verified(token, user_id, email, ip_address)
            end
            
          _ ->
            # Erro ao parsear a data de expiração
            {:error, :invalid_timestamp}
        end
        
      {:ok, %{rows: []}} ->
        # Token não encontrado ou já utilizado
        {:error, :token_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao verificar token de e-mail: #{inspect(reason)}", 
          module: __MODULE__, 
          token: token
        )
        
        {:error, reason}
    end
  end
  
  @doc """
  Marca um e-mail como verificado.
  
  ## Parâmetros
    * `token` - Token de verificação
    * `user_id` - ID do usuário
    * `email` - E-mail verificado
    * `ip_address` - Endereço IP do cliente (opcional)
  
  ## Retorno
    * `{:ok, user_id, email}` - Se o e-mail for marcado como verificado
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec mark_as_verified(String.t(), String.t(), String.t(), String.t() | nil) :: {:ok, String.t(), String.t()} | {:error, any()}
  def mark_as_verified(token, user_id, email, ip_address \\ nil) do
    # Atualiza o registro de verificação
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    update_sql = """
    UPDATE email_verifications
    SET verified_at = ?
    WHERE token = ?;
    """
    
    case Repo.execute(update_sql, [now, token]) do
      {:ok, _} ->
        # Atualiza o status de verificação do usuário
        update_user_sql = """
        UPDATE users
        SET email_verified = TRUE, updated_at = ?
        WHERE id = ? AND email = ?;
        """
        
        case Repo.execute(update_user_sql, [now, user_id, email]) do
          {:ok, _} ->
            # Registra a atividade
            ActivityLog.log_activity(user_id, :email_verified, %{
              email: email
            }, ip_address)
            
            Logger.info("E-mail verificado com sucesso: #{email}", 
              module: __MODULE__, 
              user_id: user_id
            )
            
            {:ok, user_id, email}
            
          {:error, reason} ->
            Logger.error("Erro ao atualizar status de verificação do usuário: #{inspect(reason)}", 
              module: __MODULE__, 
              user_id: user_id,
              email: email
            )
            
            {:error, reason}
        end
        
      {:error, reason} ->
        Logger.error("Erro ao marcar e-mail como verificado: #{inspect(reason)}", 
          module: __MODULE__, 
          token: token
        )
        
        {:error, reason}
    end
  end
  
  @doc """
  Reenvia o e-mail de verificação.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `email` - E-mail a ser verificado
    * `ip_address` - Endereço IP do cliente (opcional)
  
  ## Retorno
    * `{:ok, token}` - Se o e-mail for reenviado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec resend_verification(String.t(), String.t(), String.t() | nil) :: {:ok, String.t()} | {:error, any()}
  def resend_verification(user_id, email, ip_address \\ nil) do
    # Invalida tokens anteriores
    invalidate_sql = """
    UPDATE email_verifications
    SET invalidated_at = ?
    WHERE user_id = ? AND email = ? AND verified_at IS NULL AND invalidated_at IS NULL;
    """
    
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    case Repo.execute(invalidate_sql, [now, user_id, email]) do
      {:ok, _} ->
        # Solicita nova verificação
        request_verification(user_id, email, ip_address)
        
      {:error, reason} ->
        Logger.error("Erro ao invalidar tokens anteriores: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id,
          email: email
        )
        
        {:error, reason}
    end
  end
  
  @doc """
  Verifica se um e-mail já foi verificado para um usuário.
  
  ## Parâmetros
    * `user_id` - ID do usuário
    * `email` - E-mail a ser verificado
  
  ## Retorno
    * `{:ok, true}` - Se o e-mail já foi verificado
    * `{:ok, false}` - Se o e-mail ainda não foi verificado
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec is_verified?(String.t(), String.t()) :: {:ok, boolean()} | {:error, any()}
  def is_verified?(user_id, email) do
    sql = """
    SELECT email_verified
    FROM users
    WHERE id = ? AND email = ?;
    """
    
    case Repo.query(sql, [user_id, email]) do
      {:ok, %{rows: [[verified]]}} ->
        {:ok, verified}
        
      {:ok, %{rows: []}} ->
        # Usuário ou e-mail não encontrado
        {:error, :user_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao verificar status de e-mail: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id,
          email: email
        )
        
        {:error, reason}
    end
  end
  
  @doc """
  Limpa tokens de verificação expirados ou utilizados.
  
  ## Retorno
    * `{:ok, count}` - Número de tokens removidos
    * `{:error, reason}` - Se ocorrer um erro
  """
  @spec clean_tokens() :: {:ok, integer()} | {:error, any()}
  def clean_tokens do
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
        {:error, reason}
    end
  end
  
  # Gera um token de verificação único
  defp generate_verification_token do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)
  end
  
  # Envia o e-mail de verificação
  defp send_verification_email(user_id, email, token) do
    # Busca informações do usuário
    case User.get_by_id(user_id) do
      {:ok, user} ->
        # Constrói o link de verificação
        verification_url = "#{Application.get_env(:deeper_hub, :base_url)}/verify-email?token=#{token}"
        
        # Prepara o e-mail
        subject = "Verificação de E-mail - DeeperHub"
        
        body = """
        Olá #{user["name"]},
        
        Por favor, verifique seu e-mail clicando no link abaixo:
        
        #{verification_url}
        
        Este link expirará em 24 horas.
        
        Se você não solicitou esta verificação, por favor ignore este e-mail.
        
        Atenciosamente,
        Equipe DeeperHub
        """
        
        # Envia o e-mail
        Mailer.send_email(email, subject, body)
        
      {:error, reason} ->
        Logger.error("Erro ao buscar informações do usuário para envio de e-mail: #{inspect(reason)}", 
          module: __MODULE__, 
          user_id: user_id
        )
    end
  end
end
