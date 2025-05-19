defmodule DeeperHub.Config.Security do
  @moduledoc """
  Configurações de segurança para o DeeperHub.

  Este módulo centraliza todas as configurações relacionadas à segurança
  do sistema, incluindo proteção contra ataques, políticas de senha,
  configurações de sessão e outras medidas de segurança.
  """

  @doc """
  Retorna as configurações de proteção contra ataques de autenticação.

  ## Retorno
    * Mapa com as configurações
  """
  def auth_protection do
    %{
      # Tempo de bloqueio para tentativas de autenticação excessivas (em segundos)
      block_duration: get_env(:block_duration, 900),  # 15 minutos por padrão

      # Limite de tentativas de autenticação por IP
      max_auth_attempts: get_env(:max_auth_attempts, 10),  # 10 tentativas por padrão

      # Período de tempo para contar tentativas (em segundos)
      auth_period: get_env(:auth_period, 60),  # 1 minuto por padrão

      # Se deve registrar tentativas de autenticação no log de segurança
      log_auth_attempts: get_env(:log_auth_attempts, true)
    }
  end

  @doc """
  Retorna as configurações de política de senhas.

  ## Retorno
    * Mapa com as configurações
  """
  def password_policy do
    %{
      # Tamanho mínimo da senha
      min_length: get_env(:password_min_length, 8),

      # Se deve exigir letras maiúsculas
      require_uppercase: get_env(:password_require_uppercase, true),

      # Se deve exigir letras minúsculas
      require_lowercase: get_env(:password_require_lowercase, true),

      # Se deve exigir números
      require_numbers: get_env(:password_require_numbers, true),

      # Se deve exigir caracteres especiais
      require_special: get_env(:password_require_special, true),

      # Lista de caracteres especiais aceitos
      special_chars: get_env(:password_special_chars, "!@#$%^&*()-_=+[]{}|;:,.<>?/"),

      # Tempo de expiração da senha (em dias, 0 para nunca expirar)
      expiration_days: get_env(:password_expiration_days, 90),

      # Número de senhas anteriores que não podem ser reutilizadas
      history_count: get_env(:password_history_count, 5)
    }
  end

  @doc """
  Retorna as configurações de tokens JWT.

  ## Retorno
    * Mapa com as configurações
  """
  def jwt_config do
    %{
      # Tempo de expiração do token de acesso (em segundos)
      access_token_ttl: get_env(:access_token_ttl, 3600),  # 1 hora

      # Tempo de expiração do token de refresh (em segundos)
      refresh_token_ttl: get_env(:refresh_token_ttl, 30 * 24 * 3600),  # 30 dias

      # Algoritmo de assinatura
      algorithm: get_env(:jwt_algorithm, "HS512"),

      # Se deve incluir claims padrão (iat, exp, nbf, iss, aud)
      include_default_claims: get_env(:jwt_include_default_claims, true)
    }
  end

  @doc """
  Retorna as configurações de sessão.

  ## Retorno
    * Mapa com as configurações
  """
  def session_config do
    %{
      # Duração máxima de uma sessão normal (em segundos)
      session_duration: get_env(:session_duration, 24 * 60 * 60),  # 24 horas

      # Duração máxima de uma sessão persistente (em segundos)
      persistent_session_duration: get_env(:persistent_session_duration, 30 * 24 * 60 * 60),  # 30 dias

      # Timeout por inatividade (em segundos)
      inactivity_timeout: get_env(:inactivity_timeout, 60 * 60),  # 1 hora

      # Número máximo de sessões simultâneas por usuário
      max_concurrent_sessions: get_env(:max_concurrent_sessions, 5),

      # Número máximo de sessões persistentes por usuário
      max_persistent_sessions: get_env(:max_persistent_sessions, 3),

      # Se deve invalidar todas as sessões ao alterar a senha
      invalidate_on_password_change: get_env(:invalidate_on_password_change, true),

      # Se deve invalidar todas as sessões ao detectar atividade suspeita
      invalidate_on_suspicious_activity: get_env(:invalidate_on_suspicious_activity, true),

      # Se deve exigir reautenticação para ações sensíveis
      require_reauth_for_sensitive_actions: get_env(:require_reauth_for_sensitive_actions, true),

      # Tempo máximo desde a última autenticação para ações sensíveis (em segundos)
      sensitive_action_reauth_timeout: get_env(:sensitive_action_reauth_timeout, 15 * 60)  # 15 minutos
    }
  end

  @doc """
  Retorna as configurações de verificação de e-mail.

  ## Retorno
    * Mapa com as configurações
  """
  def email_verification_config do
    %{
      # Se deve exigir verificação de e-mail para login
      require_verification: get_env(:require_email_verification, true),

      # Tempo de expiração do token de verificação (em segundos)
      token_expiration: get_env(:email_verification_token_expiration, 24 * 60 * 60),  # 24 horas

      # Número máximo de tentativas de reenvio por dia
      max_resend_attempts: get_env(:email_verification_max_resend, 5)
    }
  end

  @doc """
  Retorna as configurações de proteção contra ataques gerais.

  ## Retorno
    * Mapa com as configurações
  """
  def attack_protection_config do
    %{
      # Se deve ativar proteção contra CSRF
      enable_csrf_protection: get_env(:enable_csrf_protection, true),

      # Se deve ativar proteção contra XSS
      enable_xss_protection: get_env(:enable_xss_protection, true),

      # Se deve ativar proteção contra clickjacking
      enable_clickjacking_protection: get_env(:enable_clickjacking_protection, true),

      # Se deve ativar HSTS (HTTP Strict Transport Security)
      enable_hsts: get_env(:enable_hsts, true),

      # Tempo de expiração do HSTS (em segundos)
      hsts_max_age: get_env(:hsts_max_age, 31536000),  # 1 ano

      # Se deve incluir subdomínios no HSTS
      hsts_include_subdomains: get_env(:hsts_include_subdomains, true)
    }
  end

  # Função auxiliar para obter configurações do ambiente
  defp get_env(key, default) do
    Application.get_env(:deeper_hub, :security, [])
    |> Keyword.get(key, default)
  end
end
