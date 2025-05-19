defmodule DeeperHub.Accounts do
  @moduledoc """
  Contexto principal para gerenciamento de contas de usuário no DeeperHub.

  Este módulo serve como fachada para as operações relacionadas a contas de usuário,
  incluindo autenticação, gerenciamento de perfil, sessões, dispositivos, permissões e recuperação de senha.
  """

  alias DeeperHub.Accounts.User
  alias DeeperHub.Accounts.Auth
  alias DeeperHub.Accounts.Auth.TwoFactor
  alias DeeperHub.Accounts.Auth.PasswordReset
  alias DeeperHub.Accounts.Session
  alias DeeperHub.Accounts.UserProfile
  alias DeeperHub.Accounts.DeviceManager
  alias DeeperHub.Accounts.ActivityLog
  alias DeeperHub.Accounts.AccountDeletion
  require DeeperHub.Core.Logger

  # Autenticação e Registro

  @doc """
  Registra um novo usuário no sistema.

  ## Parâmetros
    * `attrs` - Mapa com os atributos do usuário

  ## Retorno
    * `{:ok, user}` - Se o registro for bem-sucedido
    * `{:error, reason}` - Se ocorrer um erro
  """
  def register_user(attrs) do
    Auth.register_user(attrs)
  end

  @doc """
  Autentica um usuário com email e senha.

  ## Parâmetros
    * `email` - Email do usuário
    * `password` - Senha do usuário
    * `device_info` - Informações sobre o dispositivo (opcional)

  ## Retorno
    * `{:ok, %{user: user, tokens: tokens, session_id: session_id}}` - Se a autenticação for bem-sucedida
    * `{:error, reason}` - Se as credenciais forem inválidas
  """
  def authenticate_user(email, password, device_info \\ %{}) do
    with {:ok, user} <- Auth.authenticate_user(email, password),
         # Verifica se o usuário tem 2FA ativado
         {:ok, has_2fa} <- TwoFactor.has_2fa_enabled?(user["id"]) do

      if has_2fa do
        # Se 2FA estiver ativado, gera um código e retorna status pendente
        case TwoFactor.generate_and_send_code(user["id"], user["email"], device_info) do
          {:ok, _code} ->
            {:ok, %{
              user: user,
              status: :two_factor_required,
              user_id: user["id"]
            }}

          {:error, reason} ->
            {:error, reason}
        end
      else
        # Se 2FA não estiver ativado, cria sessão e gera tokens
        complete_authentication(user, device_info)
      end
    else
      error -> error
    end
  end

  @doc """
  Verifica um código de autenticação em duas etapas.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `code` - Código de verificação
    * `device_info` - Informações sobre o dispositivo (opcional)

  ## Retorno
    * `{:ok, %{user: user, tokens: tokens, session_id: session_id}}` - Se o código for válido
    * `{:error, reason}` - Se o código for inválido
  """
  def verify_two_factor_code(user_id, code, device_info \\ %{}) do
    with :ok <- TwoFactor.verify_code(user_id, code),
         {:ok, user} <- User.get(user_id) do

      # Completa a autenticação após verificação do código
      complete_authentication(user, device_info)
    else
      error -> error
    end
  end

  @doc """
  Atualiza tokens usando um token de atualização.

  ## Parâmetros
    * `refresh_token` - Token de atualização

  ## Retorno
    * `{:ok, tokens}` - Novos tokens
    * `{:error, reason}` - Se o token for inválido
  """
  def refresh_tokens(refresh_token) do
    Auth.refresh_tokens(refresh_token)
  end

  @doc """
  Encerra a sessão de um usuário.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `session_id` - ID da sessão
    * `token` - Token de acesso a ser revogado

  ## Retorno
    * `:ok` - Se a sessão for encerrada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def logout(user_id, session_id, token) do
    with :ok <- Auth.revoke_token(token),
         :ok <- Session.terminate(session_id, user_id) do

      # Registra a atividade
      ActivityLog.log_activity(user_id, :logout)

      :ok
    else
      error -> error
    end
  end

  # Gerenciamento de Perfil

  @doc """
  Atualiza o perfil de um usuário.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `attrs` - Mapa com os atributos a serem atualizados

  ## Retorno
    * `{:ok, user}` - Se o perfil for atualizado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def update_profile(user_id, attrs) do
    with {:ok, user} <- UserProfile.update_profile(user_id, attrs) do
      # Registra a atividade
      ActivityLog.log_activity(user_id, :profile_update)

      {:ok, user}
    else
      error -> error
    end
  end

  @doc """
  Altera a senha de um usuário.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `current_password` - Senha atual
    * `new_password` - Nova senha

  ## Retorno
    * `:ok` - Se a senha for alterada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def change_password(user_id, current_password, new_password) do
    with {:ok, user} <- User.get(user_id),
         {:ok, _} <- Auth.authenticate_user(user["email"], current_password),
         {:ok, _} <- User.update(user_id, %{password: new_password}) do

      # Registra a atividade
      ActivityLog.log_activity(user_id, :password_change)

      :ok
    else
      error -> error
    end
  end

  # Autenticação em Duas Etapas

  @doc """
  Ativa a autenticação em duas etapas para um usuário.

  ## Parâmetros
    * `user_id` - ID do usuário

  ## Retorno
    * `:ok` - Se a ativação for bem-sucedida
    * `{:error, reason}` - Se ocorrer um erro
  """
  def enable_two_factor(user_id) do
    with :ok <- TwoFactor.enable_2fa(user_id) do
      # Registra a atividade
      ActivityLog.log_activity(user_id, :two_factor_enabled)

      :ok
    else
      error -> error
    end
  end

  @doc """
  Desativa a autenticação em duas etapas para um usuário.

  ## Parâmetros
    * `user_id` - ID do usuário

  ## Retorno
    * `:ok` - Se a desativação for bem-sucedida
    * `{:error, reason}` - Se ocorrer um erro
  """
  def disable_two_factor(user_id) do
    with :ok <- TwoFactor.disable_2fa(user_id) do
      # Registra a atividade
      ActivityLog.log_activity(user_id, :two_factor_disabled)

      :ok
    else
      error -> error
    end
  end

  # Gerenciamento de Sessões e Dispositivos

  @doc """
  Lista as sessões ativas de um usuário.

  ## Parâmetros
    * `user_id` - ID do usuário

  ## Retorno
    * `{:ok, sessions}` - Lista de sessões ativas
    * `{:error, reason}` - Se ocorrer um erro
  """
  def list_active_sessions(user_id) do
    Session.list_active(user_id)
  end

  @doc """
  Encerra uma sessão específica.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `session_id` - ID da sessão

  ## Retorno
    * `:ok` - Se a sessão for encerrada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def terminate_session(user_id, session_id) do
    with :ok <- Session.terminate(session_id, user_id) do
      # Registra a atividade
      ActivityLog.log_activity(user_id, :session_terminated, %{session_id: session_id})

      :ok
    else
      error -> error
    end
  end

  @doc """
  Encerra todas as sessões de um usuário, exceto a atual.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `current_session_id` - ID da sessão atual

  ## Retorno
    * `{:ok, count}` - Número de sessões encerradas
    * `{:error, reason}` - Se ocorrer um erro
  """
  def terminate_all_sessions(user_id, current_session_id) do
    with {:ok, count} <- Session.terminate_all(user_id, current_session_id) do
      # Registra a atividade
      ActivityLog.log_activity(user_id, :all_sessions_terminated, %{count: count})

      {:ok, count}
    else
      error -> error
    end
  end

  @doc """
  Lista os dispositivos de um usuário.

  ## Parâmetros
    * `user_id` - ID do usuário

  ## Retorno
    * `{:ok, devices}` - Lista de dispositivos
    * `{:error, reason}` - Se ocorrer um erro
  """
  def list_devices(user_id) do
    DeviceManager.list_devices(user_id)
  end

  @doc """
  Marca um dispositivo como confiável.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `device_id` - ID do dispositivo

  ## Retorno
    * `:ok` - Se o dispositivo for marcado como confiável com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def trust_device(user_id, device_id) do
    DeviceManager.trust_device(device_id, user_id)
  end

  @doc """
  Remove um dispositivo.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `device_id` - ID do dispositivo

  ## Retorno
    * `:ok` - Se o dispositivo for removido com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def remove_device(user_id, device_id) do
    with :ok <- DeviceManager.remove_device(device_id, user_id) do
      # Registra a atividade
      ActivityLog.log_activity(user_id, :device_removed, %{device_id: device_id})

      :ok
    else
      error -> error
    end
  end

  # Registro de Atividades

  @doc """
  Lista as atividades recentes de um usuário.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `limit` - Número máximo de atividades a retornar
    * `offset` - Deslocamento para paginação

  ## Retorno
    * `{:ok, activities}` - Lista de atividades
    * `{:error, reason}` - Se ocorrer um erro
  """
  def list_recent_activities(user_id, limit \\ 20, offset \\ 0) do
    ActivityLog.list_recent_activities(user_id, limit, offset)
  end

  # Exclusão de Conta

  @doc """
  Solicita a exclusão de uma conta de usuário.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `email` - Email do usuário
    * `reason` - Motivo da exclusão (opcional)

  ## Retorno
    * `{:ok, confirmation_token}` - Se a solicitação for criada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def request_account_deletion(user_id, email, reason \\ nil) do
    AccountDeletion.request_deletion(user_id, email, reason)
  end

  @doc """
  Confirma a exclusão de uma conta de usuário.

  ## Parâmetros
    * `confirmation_token` - Token de confirmação

  ## Retorno
    * `{:ok, user_id}` - Se a confirmação for bem-sucedida
    * `{:error, reason}` - Se ocorrer um erro
  """
  def confirm_account_deletion(confirmation_token) do
    AccountDeletion.confirm_deletion(confirmation_token)
  end

  @doc """
  Cancela uma solicitação de exclusão de conta.

  ## Parâmetros
    * `confirmation_token` - Token de confirmação

  ## Retorno
    * `{:ok, user_id}` - Se o cancelamento for bem-sucedido
    * `{:error, reason}` - Se ocorrer um erro
  """
  def cancel_account_deletion(confirmation_token) do
    AccountDeletion.cancel_deletion_request(confirmation_token)
  end

  # Recuperação de Senha

  @doc """
  Solicita a recuperação de senha para um usuário.

  ## Parâmetros
    * `email` - Email do usuário

  ## Retorno
    * `{:ok, user_id}` - Se a solicitação for criada com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def request_password_reset(email) do
    PasswordReset.request_reset(email)
  end

  @doc """
  Verifica se um token de recuperação de senha é válido.

  ## Parâmetros
    * `token` - Token de recuperação

  ## Retorno
    * `{:ok, user_id}` - Se o token for válido
    * `{:error, reason}` - Se o token for inválido
  """
  def verify_password_reset_token(token) do
    PasswordReset.verify_token(token)
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
    PasswordReset.reset_password(token, new_password)
  end

  # Funções privadas

  # Completa o processo de autenticação após validação de credenciais
  defp complete_authentication(user, device_info) do
    user_id = user["id"]

    # Cria uma nova sessão
    with {:ok, session_id} <- Session.create(user_id, device_info),
         # Verifica o dispositivo
         {:ok, device_status} <- DeviceManager.check_device(user_id, device_info),
         # Gera tokens de acesso e atualização
         {:ok, tokens} <- Auth.generate_tokens(user) do

      # Registra a atividade de login
      ActivityLog.log_activity(user_id, :login, %{
        device_info: device_info,
        session_id: session_id
      }, Map.get(device_info, :ip))

      # Se for um novo dispositivo, notifica o usuário
      if device_status == :new_device do
        # Registra o novo dispositivo
        {:ok, device_id} = DeviceManager.register_device(user_id, device_info, false)

        # Envia notificação de novo dispositivo
        DeviceManager.notify_new_device_login(user_id, user["email"], device_info)

        # Retorna informações completas de autenticação
        {:ok, %{
          user: user,
          tokens: tokens,
          session_id: session_id,
          new_device: true,
          device_id: device_id
        }}
      else
        # Retorna informações completas de autenticação
        {:ok, %{
          user: user,
          tokens: tokens,
          session_id: session_id,
          new_device: false
        }}
      end
    else
      error -> error
    end
  end
end
