defmodule Deeper_Hub.Core.WebSockets.Security.SecurityIntegrationTest do
  use ExUnit.Case, async: false

  alias Deeper_Hub.Core.WebSockets.Security.SecurityConfig

  # Setup global para todos os testes
  setup_all do
    # Configura o ambiente de teste com valores padrão
    Application.put_env(:deeper_hub, :security, %{
      xss_protection: true,
      sql_injection_protection: true,
      path_traversal_protection: true,
      rate_limiting: true,
      ip_blacklist: ["192.168.1.100"],
      user_agent_blacklist: ["Bad-Bot"],
      max_requests_per_minute: 60,
      max_payload_size_kb: 100
    })
    
    # Captura a configuração original para restaurar depois
    original_config = Application.get_env(:deeper_hub, :security)
    
    on_exit(fn -> 
      # Restaura configuração original
      Application.put_env(:deeper_hub, :security, original_config)
    end)
    
    :ok
  end

  describe "Integração com SecurityConfig" do
    test "respeita configurações de recursos habilitados/desabilitados" do
      # Salva configuração original
      original_config = Application.get_env(:deeper_hub, :security)

      # Configura XSS como desabilitado usando a estrutura correta
      # O método is_feature_enabled? espera uma estrutura aninhada com a chave :enabled
      new_config = Map.put(original_config, :xss, %{enabled: false})
      Application.put_env(:deeper_hub, :security, new_config)

      # Verifica que o recurso está desabilitado
      assert SecurityConfig.is_feature_enabled?(:xss) == false

      # Restaura configuração
      Application.put_env(:deeper_hub, :security, original_config)
    end
  end
end
