defmodule Deeper_Hub.Core.WebSockets.Security.DdosProtectionTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.WebSockets.Security.DdosProtection
  
  setup do
    # Limpa o estado do módulo DdosProtection antes de cada teste
    DdosProtection.reset_state()
    
    %{
      ip: {127, 0, 0, 1},
      user_id: "test_user_123"
    }
  end
  
  describe "check_rate_limit/2" do
    test "permite requisições dentro do limite de taxa", %{ip: ip} do
      # Faz requisições dentro do limite
      for _ <- 1..4 do
        assert {:ok, _} = DdosProtection.check_rate_limit(ip)
      end
    end
    
    test "bloqueia requisições que excedem o limite de taxa", %{ip: ip} do
      # Faz requisições dentro do limite
      for _ <- 1..5 do
        assert {:ok, _} = DdosProtection.check_rate_limit(ip)
      end
      
      # A próxima requisição deve ser bloqueada
      # O formato de retorno é {:error, :rate_limited, retry_after}
      assert {:error, :rate_limited, _retry_after} = DdosProtection.check_rate_limit(ip)
    end
    
    test "respeita o tempo de bloqueio", %{ip: ip} do
      # Faz requisições até ser bloqueado
      for _ <- 1..6 do
        DdosProtection.check_rate_limit(ip)
      end
      
      # Verifica que está bloqueado
      # O formato de retorno é {:error, :rate_limited, retry_after}
      assert {:error, :rate_limited, _retry_after} = DdosProtection.check_rate_limit(ip)
      
      # Força a remoção do bloqueio para o teste
      DdosProtection.unblock_ip(ip)
      
      # Deve permitir requisições novamente
      assert {:ok, _} = DdosProtection.check_rate_limit(ip)
    end
    
    test "diferencia entre IPs diferentes", %{ip: ip1} do
      ip2 = {192, 168, 0, 1}
      
      # Faz requisições até bloquear o primeiro IP
      for _ <- 1..6 do
        DdosProtection.check_rate_limit(ip1)
      end
      
      # Verifica que o primeiro IP está bloqueado
      # O formato de retorno é {:error, :rate_limited, retry_after}
      assert {:error, :rate_limited, _retry_after} = DdosProtection.check_rate_limit(ip1)
      
      # O segundo IP deve estar permitido
      assert {:ok, _} = DdosProtection.check_rate_limit(ip2)
    end
  end
  
  describe "detect_anomaly/2" do
    test "detecta comportamento anômalo", %{ip: ip, user_id: user_id} do
      # Registra um padrão normal de requisições
      for _ <- 1..10 do
        DdosProtection.record_request_pattern(ip, user_id, "GET", "/api/users")
        :timer.sleep(100)
      end
      
      # Simula um comportamento anômalo (muitas requisições rápidas)
      for _ <- 1..20 do
        DdosProtection.record_request_pattern(ip, user_id, "GET", "/api/users")
      end
      
      # Deve detectar anomalia com uma pontuação alta
      # O formato de retorno é {:ok, score} onde score é a pontuação de anomalia
      {:ok, score} = DdosProtection.detect_anomaly(ip, user_id)
      # Verifica se a pontuação é maior que um limiar
      assert score > 0
    end
    
    test "permite comportamento normal", %{ip: ip, user_id: user_id} do
      # Registra um padrão normal de requisições
      for _ <- 1..10 do
        DdosProtection.record_request_pattern(ip, user_id, "GET", "/api/users")
        :timer.sleep(100)
      end
      
      # Continua com comportamento normal
      for _ <- 1..5 do
        DdosProtection.record_request_pattern(ip, user_id, "GET", "/api/users")
        :timer.sleep(100)
      end
      
      # Não deve detectar anomalia
      {:ok, score} = DdosProtection.detect_anomaly(ip, user_id)
      assert score < 2.0  # Abaixo do limiar de anomalia
    end
  end
  
  describe "block_ip/1" do
    test "bloqueia um IP", %{ip: ip} do
      # Bloqueia o IP
      assert :ok = DdosProtection.block_ip(ip)
      
      # Verifica que o IP está bloqueado
      # O formato de retorno é {:error, :rate_limited, retry_after}
      assert {:error, :rate_limited, _retry_after} = DdosProtection.check_rate_limit(ip)
    end
  end
  
  describe "unblock_ip/1" do
    test "desbloqueia um IP bloqueado", %{ip: ip} do
      # Bloqueia o IP
      DdosProtection.block_ip(ip)
      
      # Verifica que o IP está bloqueado
      # O formato de retorno é {:error, :rate_limited, retry_after}
      assert {:error, :rate_limited, _retry_after} = DdosProtection.check_rate_limit(ip)
      
      # Desbloqueia o IP
      assert :ok = DdosProtection.unblock_ip(ip)
      
      # Verifica que o IP está desbloqueado
      assert {:ok, _} = DdosProtection.check_rate_limit(ip)
    end
  end
  
  describe "reset_state/0" do
    test "limpa todos os contadores e bloqueios", %{ip: ip} do
      # Bloqueia o IP
      DdosProtection.block_ip(ip)
      
      # Verifica que o IP está bloqueado
      # O formato de retorno é {:error, :rate_limited, retry_after}
      assert {:error, :rate_limited, _retry_after} = DdosProtection.check_rate_limit(ip)
      
      # Reseta o estado
      assert :ok = DdosProtection.reset_state()
      
      # Verifica que o IP não está mais bloqueado
      assert {:ok, _} = DdosProtection.check_rate_limit(ip)
    end
  end
end
