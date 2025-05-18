defmodule Deeper_Hub.Core.WebSockets.Auth.Session.SessionPolicy do
  @moduledoc """
  Define políticas para sessões de usuário.
  
  Este módulo estabelece regras para:
  - Duração máxima de sessões
  - Timeout por inatividade
  - Número máximo de sessões simultâneas
  - Outras políticas relacionadas à segurança de sessões
  """
  
  # Removido alias não utilizado
  
  # Valores padrão para políticas de sessão
  @default_access_token_expiry 3600          # 1 hora em segundos
  @default_refresh_token_expiry 2_592_000    # 30 dias em segundos
  @default_remember_me_expiry 15_552_000     # 180 dias em segundos
  @default_inactivity_timeout 1_800          # 30 minutos em segundos
  @default_max_sessions_per_user 5           # Número máximo de sessões simultâneas
  
  @doc """
  Retorna a duração de expiração para tokens de acesso.
  
  ## Retorno
  
    - Duração em segundos
  """
  def access_token_expiry do
    get_config(:access_token_expiry, @default_access_token_expiry)
  end
  
  @doc """
  Retorna a duração de expiração para tokens de refresh.
  
  ## Retorno
  
    - Duração em segundos
  """
  def refresh_token_expiry do
    get_config(:refresh_token_expiry, @default_refresh_token_expiry)
  end
  
  @doc """
  Retorna a duração de expiração para tokens de refresh com "lembrar-me" ativado.
  
  ## Retorno
  
    - Duração em segundos
  """
  def remember_me_expiry do
    get_config(:remember_me_expiry, @default_remember_me_expiry)
  end
  
  @doc """
  Retorna o timeout por inatividade para sessões.
  
  ## Retorno
  
    - Duração em segundos
  """
  def inactivity_timeout do
    get_config(:inactivity_timeout, @default_inactivity_timeout)
  end
  
  @doc """
  Retorna o número máximo de sessões simultâneas por usuário.
  
  ## Retorno
  
    - Número máximo de sessões
  """
  def max_sessions_per_user do
    get_config(:max_sessions_per_user, @default_max_sessions_per_user)
  end
  
  @doc """
  Verifica se uma sessão deve ser encerrada por inatividade.
  
  ## Parâmetros
  
    - `last_activity`: Timestamp da última atividade da sessão
    
  ## Retorno
  
    - `true` se a sessão deve ser encerrada
    - `false` caso contrário
  """
  def should_timeout?(last_activity) do
    timeout = inactivity_timeout()
    now = DateTime.utc_now()
    diff = DateTime.diff(now, last_activity, :second)
    
    diff > timeout
  end
  
  # Função privada para obter configurações
  defp get_config(key, default) do
    case Application.get_env(:deeper_hub, :session_policy) do
      nil -> default
      config -> Keyword.get(config, key, default)
    end
  end
end
