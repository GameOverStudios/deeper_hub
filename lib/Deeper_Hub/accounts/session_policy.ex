defmodule DeeperHub.Accounts.SessionPolicy do
  @moduledoc """
  Módulo para gerenciamento de políticas de sessão no DeeperHub.

  Este módulo define políticas para sessões de usuário, incluindo
  duração máxima, timeout por inatividade, número máximo de sessões
  simultâneas e outras configurações de segurança.
  """

  require DeeperHub.Core.Logger

  # Políticas padrão para sessões
  @default_policies %{
    # Duração máxima de uma sessão normal (em segundos)
    session_duration: 24 * 60 * 60,  # 24 horas

    # Duração máxima de uma sessão persistente (em segundos)
    persistent_session_duration: 30 * 24 * 60 * 60,  # 30 dias

    # Timeout por inatividade (em segundos)
    inactivity_timeout: 60 * 60,  # 1 hora

    # Número máximo de sessões simultâneas por usuário
    max_concurrent_sessions: 5,

    # Número máximo de sessões persistentes por usuário
    max_persistent_sessions: 3,

    # Se deve invalidar todas as sessões ao alterar a senha
    invalidate_on_password_change: true,

    # Se deve invalidar todas as sessões ao detectar atividade suspeita
    invalidate_on_suspicious_activity: true,

    # Se deve exigir reautenticação para ações sensíveis
    require_reauth_for_sensitive_actions: true,

    # Tempo máximo desde a última autenticação para ações sensíveis (em segundos)
    sensitive_action_reauth_timeout: 15 * 60  # 15 minutos
  }

  @doc """
  Obtém as políticas de sessão para um usuário específico.

  Este método permite personalizar políticas por usuário ou papel,
  mas atualmente retorna as políticas padrão para todos os usuários.

  ## Parâmetros
    * `user_id` - ID do usuário (opcional)
    * `role` - Papel do usuário (opcional)

  ## Retorno
    * Mapa com as políticas de sessão
  """
  @spec get_policies(String.t() | nil, String.t() | nil) :: map()
  def get_policies(_user_id \\ nil, role \\ nil) do
    # Obtém políticas específicas do ambiente
    env_policies = Application.get_env(:deeper_hub, :session_policies, %{})

    # Combina com as políticas padrão
    policies = Map.merge(@default_policies, env_policies)

    # Aplica modificações baseadas no papel do usuário
    case role do
      "admin" ->
        # Administradores têm políticas mais restritivas
        Map.merge(policies, %{
          inactivity_timeout: 30 * 60,  # 30 minutos
          sensitive_action_reauth_timeout: 5 * 60  # 5 minutos
        })

      _ ->
        # Políticas padrão para outros papéis
        policies
    end
  end

  @doc """
  Verifica se um usuário pode criar uma nova sessão.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `persistent` - Se a sessão será persistente
    * `current_sessions` - Lista de sessões atuais do usuário

  ## Retorno
    * `:ok` - Se o usuário pode criar uma nova sessão
    * `{:error, :max_sessions_reached}` - Se o usuário atingiu o limite de sessões
    * `{:error, :max_persistent_sessions_reached}` - Se o usuário atingiu o limite de sessões persistentes
  """
  @spec can_create_session?(String.t(), boolean(), [map()]) :: :ok | {:error, atom()}
  def can_create_session?(user_id, persistent, current_sessions) do
    # Obtém as políticas para o usuário
    policies = get_policies(user_id)

    # Conta o número de sessões atuais
    session_count = length(current_sessions)

    # Verifica se o usuário atingiu o limite de sessões
    if session_count >= policies.max_concurrent_sessions do
      {:error, :max_sessions_reached}
    else
      if persistent do
        # Conta o número de sessões persistentes
        persistent_count = Enum.count(current_sessions, & &1["persistent"])

        # Verifica se o usuário atingiu o limite de sessões persistentes
        if persistent_count >= policies.max_persistent_sessions do
          {:error, :max_persistent_sessions_reached}
        else
          :ok
        end
      else
        :ok
      end
    end
  end

  @doc """
  Verifica se uma ação sensível requer reautenticação.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `last_auth_time` - Timestamp da última autenticação (DateTime)

  ## Retorno
    * `{:ok, false}` - Se não requer reautenticação
    * `{:ok, true}` - Se requer reautenticação
  """
  @spec requires_reauth?(String.t(), DateTime.t()) :: {:ok, boolean()}
  def requires_reauth?(user_id, last_auth_time) do
    # Obtém as políticas para o usuário
    policies = get_policies(user_id)

    # Verifica se requer reautenticação para ações sensíveis
    if policies.require_reauth_for_sensitive_actions do
      # Calcula o tempo decorrido desde a última autenticação
      now = DateTime.utc_now()
      diff = DateTime.diff(now, last_auth_time, :second)

      # Verifica se excedeu o timeout para ações sensíveis
      {:ok, diff > policies.sensitive_action_reauth_timeout}
    else
      {:ok, false}
    end
  end

  @doc """
  Obtém a duração de uma sessão com base nas políticas.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `persistent` - Se a sessão será persistente

  ## Retorno
    * Duração da sessão em segundos
  """
  @spec get_session_duration(String.t(), boolean()) :: integer()
  def get_session_duration(user_id, persistent) do
    # Obtém as políticas para o usuário
    policies = get_policies(user_id)

    # Retorna a duração apropriada
    if persistent do
      policies.persistent_session_duration
    else
      policies.session_duration
    end
  end

  @doc """
  Obtém o timeout por inatividade com base nas políticas.

  ## Parâmetros
    * `user_id` - ID do usuário

  ## Retorno
    * Timeout por inatividade em segundos
  """
  @spec get_inactivity_timeout(String.t()) :: integer()
  def get_inactivity_timeout(user_id) do
    # Obtém as políticas para o usuário
    policies = get_policies(user_id)

    # Retorna o timeout por inatividade
    policies.inactivity_timeout
  end

  @doc """
  Verifica se deve invalidar todas as sessões ao alterar a senha.

  ## Parâmetros
    * `user_id` - ID do usuário

  ## Retorno
    * `true` ou `false`
  """
  @spec should_invalidate_on_password_change?(String.t()) :: boolean()
  def should_invalidate_on_password_change?(user_id) do
    # Obtém as políticas para o usuário
    policies = get_policies(user_id)

    # Retorna a política
    policies.invalidate_on_password_change
  end

  @doc """
  Verifica se deve invalidar todas as sessões ao detectar atividade suspeita.

  ## Parâmetros
    * `user_id` - ID do usuário

  ## Retorno
    * `true` ou `false`
  """
  @spec should_invalidate_on_suspicious_activity?(String.t()) :: boolean()
  def should_invalidate_on_suspicious_activity?(user_id) do
    # Obtém as políticas para o usuário
    policies = get_policies(user_id)

    # Retorna a política
    policies.invalidate_on_suspicious_activity
  end
end
