defmodule Deeper_Hub.Core.WebSockets.Security.SecurityConfigTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.WebSockets.Security.SecurityConfig
  
  setup do
    # Salva as configurações originais
    original_config = Application.get_env(:deeper_hub, :security, %{})
    
    # Configura valores de teste
    test_config = %{
      csrf: %{
        enabled: true,
        allowed_origins: ["http://localhost", "https://example.com"],
        token_expiry: 3600
      },
      ddos: %{
        enabled: true,
        rate_limit: 100,
        time_window: 60,
        block_duration: 300,
        anomaly_threshold: 2.0
      },
      brute_force: %{
        enabled: true,
        max_attempts: 5,
        block_duration: 900,
        attempt_window: 300
      },
      xss: %{
        enabled: true
      },
      sql_injection: %{
        enabled: true
      },
      path_traversal: %{
        enabled: true,
        base_dir: "/var/www"
      }
    }
    
    Application.put_env(:deeper_hub, :security, test_config)
    
    on_exit(fn ->
      # Restaura as configurações originais
      Application.put_env(:deeper_hub, :security, original_config)
    end)
    
    %{test_config: test_config}
  end
  
  describe "get_csrf_config/2" do
    test "retorna valor configurado quando existe", %{test_config: config} do
      assert SecurityConfig.get_csrf_config(:enabled) == config.csrf.enabled
      assert SecurityConfig.get_csrf_config(:allowed_origins) == config.csrf.allowed_origins
      assert SecurityConfig.get_csrf_config(:token_expiry) == config.csrf.token_expiry
    end
    
    test "retorna valor padrão quando configuração não existe" do
      assert SecurityConfig.get_csrf_config(:non_existent, "default") == "default"
    end
  end
  
  describe "get_ddos_config/2" do
    test "retorna valor configurado quando existe", %{test_config: config} do
      assert SecurityConfig.get_ddos_config(:enabled) == config.ddos.enabled
      assert SecurityConfig.get_ddos_config(:rate_limit) == config.ddos.rate_limit
      assert SecurityConfig.get_ddos_config(:time_window) == config.ddos.time_window
      assert SecurityConfig.get_ddos_config(:block_duration) == config.ddos.block_duration
      assert SecurityConfig.get_ddos_config(:anomaly_threshold) == config.ddos.anomaly_threshold
    end
    
    test "retorna valor padrão quando configuração não existe" do
      assert SecurityConfig.get_ddos_config(:non_existent, "default") == "default"
    end
  end
  
  describe "get_brute_force_config/2" do
    test "retorna valor configurado quando existe", %{test_config: config} do
      assert SecurityConfig.get_brute_force_config(:enabled) == config.brute_force.enabled
      assert SecurityConfig.get_brute_force_config(:max_attempts) == config.brute_force.max_attempts
      assert SecurityConfig.get_brute_force_config(:block_duration) == config.brute_force.block_duration
      assert SecurityConfig.get_brute_force_config(:attempt_window) == config.brute_force.attempt_window
    end
    
    test "retorna valor padrão quando configuração não existe" do
      assert SecurityConfig.get_brute_force_config(:non_existent, "default") == "default"
    end
  end
  
  describe "get_xss_config/2" do
    test "retorna valor configurado quando existe", %{test_config: config} do
      assert SecurityConfig.get_xss_config(:enabled) == config.xss.enabled
    end
    
    test "retorna valor padrão quando configuração não existe" do
      assert SecurityConfig.get_xss_config(:non_existent, "default") == "default"
    end
  end
  
  describe "get_sql_injection_config/2" do
    test "retorna valor configurado quando existe", %{test_config: config} do
      assert SecurityConfig.get_sql_injection_config(:enabled) == config.sql_injection.enabled
    end
    
    test "retorna valor padrão quando configuração não existe" do
      assert SecurityConfig.get_sql_injection_config(:non_existent, "default") == "default"
    end
  end
  
  describe "get_path_traversal_config/2" do
    test "retorna valor configurado quando existe", %{test_config: config} do
      assert SecurityConfig.get_path_traversal_config(:enabled) == config.path_traversal.enabled
      assert SecurityConfig.get_path_traversal_config(:base_dir) == config.path_traversal.base_dir
    end
    
    test "retorna valor padrão quando configuração não existe" do
      assert SecurityConfig.get_path_traversal_config(:non_existent, "default") == "default"
    end
  end
  
  describe "is_feature_enabled?/1" do
    test "retorna true para recursos habilitados" do
      assert SecurityConfig.is_feature_enabled?(:csrf) == true
      assert SecurityConfig.is_feature_enabled?(:ddos) == true
      assert SecurityConfig.is_feature_enabled?(:brute_force) == true
      assert SecurityConfig.is_feature_enabled?(:xss) == true
      assert SecurityConfig.is_feature_enabled?(:sql_injection) == true
      assert SecurityConfig.is_feature_enabled?(:path_traversal) == true
    end
    
    test "retorna false para recursos desabilitados" do
      # Desabilita temporariamente um recurso
      original_config = Application.get_env(:deeper_hub, :security)
      updated_config = put_in(original_config.csrf.enabled, false)
      Application.put_env(:deeper_hub, :security, updated_config)
      
      assert SecurityConfig.is_feature_enabled?(:csrf) == false
      
      # Restaura a configuração
      Application.put_env(:deeper_hub, :security, original_config)
    end
    
    test "retorna false para recursos não configurados" do
      assert SecurityConfig.is_feature_enabled?(:non_existent) == false
    end
  end
  
  describe "update_config/3" do
    test "atualiza configuração existente" do
      # Atualiza uma configuração
      assert :ok = SecurityConfig.update_config(:csrf, :token_expiry, 7200)
      
      # Verifica se foi atualizada
      assert SecurityConfig.get_csrf_config(:token_expiry) == 7200
    end
    
    test "cria configuração não existente" do
      # Cria uma nova configuração
      assert :ok = SecurityConfig.update_config(:csrf, :new_setting, "value")
      
      # Verifica se foi criada
      assert SecurityConfig.get_csrf_config(:new_setting) == "value"
    end
  end
end
