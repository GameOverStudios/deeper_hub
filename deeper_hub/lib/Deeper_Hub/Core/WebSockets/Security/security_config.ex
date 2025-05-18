defmodule Deeper_Hub.Core.WebSockets.Security.SecurityConfig do
  @moduledoc """
  Configurações para os módulos de segurança WebSocket.
  
  Este módulo fornece uma interface centralizada para configurações
  relacionadas à segurança, com valores padrão sensatos e capacidade
  de sobrescrever via configuração da aplicação.
  """
  
  @doc """
  Obtém uma configuração específica para proteção contra CSRF.
  
  ## Parâmetros
  
    - `key`: Chave da configuração
    - `default`: Valor padrão caso a configuração não exista
  
  ## Retorno
  
    - O valor da configuração ou o valor padrão
  """
  def get_csrf_config(key, default \\ nil) do
    get_config(:csrf, key, default)
  end
  
  @doc """
  Obtém uma configuração específica para proteção contra XSS.
  
  ## Parâmetros
  
    - `key`: Chave da configuração
    - `default`: Valor padrão caso a configuração não exista
  
  ## Retorno
  
    - O valor da configuração ou o valor padrão
  """
  def get_xss_config(key, default \\ nil) do
    get_config(:xss, key, default)
  end
  
  @doc """
  Obtém uma configuração específica para proteção contra SQL Injection.
  
  ## Parâmetros
  
    - `key`: Chave da configuração
    - `default`: Valor padrão caso a configuração não exista
  
  ## Retorno
  
    - O valor da configuração ou o valor padrão
  """
  def get_sql_injection_config(key, default \\ nil) do
    get_config(:sql_injection, key, default)
  end
  
  @doc """
  Obtém uma configuração específica para proteção contra Path Traversal.
  
  ## Parâmetros
  
    - `key`: Chave da configuração
    - `default`: Valor padrão caso a configuração não exista
  
  ## Retorno
  
    - O valor da configuração ou o valor padrão
  """
  def get_path_traversal_config(key, default \\ nil) do
    get_config(:path_traversal, key, default)
  end
  
  @doc """
  Obtém uma configuração específica para proteção contra DDoS.
  
  ## Parâmetros
  
    - `key`: Chave da configuração
    - `default`: Valor padrão caso a configuração não exista
  
  ## Retorno
  
    - O valor da configuração ou o valor padrão
  """
  def get_ddos_config(key, default \\ nil) do
    get_config(:ddos, key, default)
  end
  
  @doc """
  Obtém uma configuração específica para proteção contra Força Bruta.
  
  ## Parâmetros
  
    - `key`: Chave da configuração
    - `default`: Valor padrão caso a configuração não exista
  
  ## Retorno
  
    - O valor da configuração ou o valor padrão
  """
  def get_brute_force_config(key, default \\ nil) do
    get_config(:brute_force, key, default)
  end
  
  @doc """
  Obtém uma configuração específica para o middleware de segurança.
  
  ## Parâmetros
  
    - `key`: Chave da configuração
    - `default`: Valor padrão caso a configuração não exista
  
  ## Retorno
  
    - O valor da configuração ou o valor padrão
  """
  def get_middleware_config(key, default \\ nil) do
    get_config(:middleware, key, default)
  end
  
  # Função privada para obter configurações
  defp get_config(module, key, default) do
    config = Application.get_env(:deeper_hub, :security, %{})
    module_config = Map.get(config, module, %{})
    Map.get(module_config, key, default)
  end
  
  @doc """
  Retorna todas as configurações de segurança.
  
  ## Retorno
  
    - Mapa com todas as configurações
  """
  def get_all_config do
    Application.get_env(:deeper_hub, :security, %{})
  end
  
  @doc """
  Retorna as configurações padrão para todos os módulos de segurança.
  
  ## Retorno
  
    - Mapa com as configurações padrão
  """
  def default_config do
    %{
      csrf: %{
        enabled: true,
        check_origin: true,
        check_token: true,
        allowed_origins: ["http://localhost", "https://localhost"]
      },
      xss: %{
        enabled: true,
        sanitize_html: true,
        block_scripts: true,
        allowed_tags: ["b", "i", "u", "p", "br", "span", "div"]
      },
      sql_injection: %{
        enabled: true,
        check_queries: true,
        sanitize_inputs: true,
        block_dangerous_keywords: true
      },
      path_traversal: %{
        enabled: true,
        check_paths: true,
        allowed_base_dirs: ["/tmp", "/var/www"]
      },
      ddos: %{
        enabled: true,
        rate_limit: 100,
        time_window: 60_000,
        block_time: 300_000,
        anomaly_threshold: 75
      },
      brute_force: %{
        enabled: true,
        max_attempts: 5,
        lockout_time: 900_000,
        window_time: 300_000,
        progressive_lockout: true
      },
      middleware: %{
        enabled: true,
        log_violations: true,
        publish_events: true,
        block_suspicious_ips: true
      }
    }
  end

  @doc """
  Verifica se um recurso de segurança específico está habilitado.
  
  ## Parâmetros
  
    - `feature`: Nome do recurso de segurança (:csrf, :xss, etc.)
  
  ## Retorno
  
    - `true` se o recurso estiver habilitado
    - `false` caso contrário
  """
  def is_feature_enabled?(feature) when is_atom(feature) do
    config = Application.get_env(:deeper_hub, :security, %{})
    # Verifica se o recurso existe na configuração
    if Map.has_key?(config, feature) do
      feature_config = Map.get(config, feature, %{})
      Map.get(feature_config, :enabled, true)  # Habilitado por padrão se existir na configuração
    else
      false  # Desabilitado por padrão se não existir na configuração
    end
  end

  @doc """
  Atualiza uma configuração específica de segurança.
  
  ## Parâmetros
  
    - `feature`: Nome do recurso de segurança (:csrf, :xss, etc.)
    - `key`: Chave da configuração a ser atualizada
    - `value`: Novo valor para a configuração
  
  ## Retorno
  
    - `:ok` se a atualização for bem-sucedida
  """
  def update_config(feature, key, value) when is_atom(feature) and is_atom(key) do
    current_config = Application.get_env(:deeper_hub, :security, %{})
    feature_config = Map.get(current_config, feature, %{})
    updated_feature_config = Map.put(feature_config, key, value)
    updated_config = Map.put(current_config, feature, updated_feature_config)
    
    Application.put_env(:deeper_hub, :security, updated_config)
    :ok
  end
end
