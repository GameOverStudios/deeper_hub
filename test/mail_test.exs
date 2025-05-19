#!/usr/bin/env elixir

# Script para testar o sistema de email do DeeperHub
# Uso: mix run test/mail_test.exs

defmodule DeeperHub.MailTest do
  @moduledoc """
  Script para testar o sistema de email do DeeperHub.
  
  Este script testa diferentes funcionalidades do sistema de email:
  1. Envio direto
  2. Envio via fila
  3. Envio assíncrono
  4. Diferentes tipos de emails (alerta, boas-vindas, redefinição de senha)
  """
  
  alias DeeperHub.Core.Mail
  alias DeeperHub.Core.Mail.Queue
  
  @test_email "teste@exemplo.com"
  
  def run do
    IO.puts("\n=== Teste do Sistema de Email do DeeperHub ===\n")
    
    # Verifica se estamos em modo de teste
    test_mode = Application.get_env(:deeper_hub, :mail, []) |> Keyword.get(:test_mode, false)
    IO.puts("Modo de teste: #{test_mode}")
    
    unless test_mode do
      IO.puts("\nATENÇÃO: O sistema não está em modo de teste!")
      IO.puts("Os emails serão realmente enviados para os destinatários.")
      
      unless confirmar_continuacao() do
        IO.puts("Teste cancelado pelo usuário.")
        System.halt(0)
      end
    end
    
    # Testa diferentes tipos de envio
    teste_envio_direto()
    teste_envio_fila()
    teste_envio_assincrono()
    
    # Testa diferentes tipos de emails
    teste_alerta_seguranca()
    teste_boas_vindas()
    teste_redefinicao_senha()
    teste_verificacao_codigo()
    teste_convite()
    teste_confirmacao_acao()
    teste_novo_dispositivo()
    teste_notificacao_seguranca()
    teste_atualizacao_sistema()
    
    # Verifica estatísticas da fila
    exibir_estatisticas_fila()
    
    IO.puts("\n=== Teste concluído com sucesso! ===\n")
  end
  
  defp teste_envio_direto do
    IO.puts("\n--- Testando envio direto ---")
    
    resultado = Mail.send_email(
      @test_email,
      "Teste de Envio Direto",
      :welcome,
      %{username: "Usuário Teste"},
      [use_queue: false]
    )
    
    IO.puts("Resultado: #{inspect(resultado)}")
  end
  
  defp teste_envio_fila do
    IO.puts("\n--- Testando envio via fila ---")
    
    resultado = Mail.send_email(
      @test_email,
      "Teste de Envio via Fila",
      :welcome,
      %{username: "Usuário Teste"},
      [use_queue: true, priority: :normal]
    )
    
    IO.puts("Resultado: #{inspect(resultado)}")
    
    # Aguarda um pouco para o processamento da fila
    Process.sleep(2000)
  end
  
  defp teste_envio_assincrono do
    IO.puts("\n--- Testando envio assíncrono ---")
    
    resultado = Mail.send_email(
      @test_email,
      "Teste de Envio Assíncrono",
      :welcome,
      %{username: "Usuário Teste"},
      [use_queue: false, async: true]
    )
    
    IO.puts("Resultado: #{inspect(resultado)}")
    
    # Aguarda um pouco para o processamento assíncrono
    Process.sleep(2000)
  end
  
  defp teste_alerta_seguranca do
    IO.puts("\n--- Testando email de alerta de segurança ---")
    
    # Testa diferentes severidades
    [:info, :warning, :critical]
    |> Enum.each(fn severity ->
      IO.puts("  Testando severidade: #{severity}")
      
      resultado = Mail.send_security_alert(
        @test_email,
        "Teste de Segurança",
        "Este é um teste de alerta de segurança com severidade #{severity}",
        %{
          ip: "192.168.1.100",
          tentativas: 5,
          timestamp: DateTime.utc_now()
        },
        severity,
        [use_queue: true]
      )
      
      IO.puts("  Resultado: #{inspect(resultado)}")
    end)
    
    # Aguarda um pouco para o processamento da fila
    Process.sleep(2000)
  end
  
  defp teste_boas_vindas do
    IO.puts("\n--- Testando email de boas-vindas ---")
    
    # Teste sem URL de verificação
    resultado1 = Mail.send_welcome_email(
      @test_email,
      "Usuário Teste",
      nil,
      [use_queue: true]
    )
    
    IO.puts("Resultado (sem verificação): #{inspect(resultado1)}")
    
    # Teste com URL de verificação
    resultado2 = Mail.send_welcome_email(
      @test_email,
      "Usuário Teste",
      "https://deeperhub.com/verificar/token123",
      [use_queue: true]
    )
    
    IO.puts("Resultado (com verificação): #{inspect(resultado2)}")
    
    # Aguarda um pouco para o processamento da fila
    Process.sleep(2000)
  end
  
  defp teste_redefinicao_senha do
    IO.puts("\n--- Testando email de redefinição de senha ---")
    
    resultado = Mail.send_password_reset(
      @test_email,
      "Usuário Teste",
      "https://deeperhub.com/redefinir/token456",
      24,
      [use_queue: true, priority: :high]
    )
    
    IO.puts("Resultado: #{inspect(resultado)}")
    
    # Aguarda um pouco para o processamento da fila
    Process.sleep(2000)
  end
  
  defp teste_verificacao_codigo do
    IO.puts("\n--- Testando email de código de verificação ---")
    
    resultado = Mail.send_email(
      @test_email,
      "Seu código de verificação",
      :verification_code,
      %{
        code: "123456",
        expires_in_minutes: 15,
        device_info: %{
          browser: "Chrome 98.0.4758.102",
          os: "Windows 10",
          ip: "187.122.45.67",
          location: "São Paulo, Brasil"
        }
      },
      [use_queue: true, priority: :high]
    )
    
    IO.puts("Resultado: #{inspect(resultado)}")
    
    # Aguarda um pouco para o processamento da fila
    Process.sleep(2000)
  end
  
  defp teste_convite do
    IO.puts("\n--- Testando email de convite ---")
    
    resultado = Mail.send_email(
      @test_email,
      "Convite para projeto",
      :invitation,
      %{
        inviter_name: "Maria Silva",
        resource_type: "projeto",
        resource_name: "DeeperHub - Fase 2",
        invitation_link: "https://deeperhub.com/convites/abc123",
        expires_in_days: 14,
        message: "Olá! Gostaria de convidar você para colaborar neste projeto importante."
      },
      [use_queue: true]
    )
    
    IO.puts("Resultado: #{inspect(resultado)}")
    
    # Aguarda um pouco para o processamento da fila
    Process.sleep(2000)
  end
  
  defp teste_confirmacao_acao do
    IO.puts("\n--- Testando email de confirmação de ação ---")
    
    resultado = Mail.send_email(
      @test_email,
      "Confirmação de exclusão de conta",
      :action_confirmation,
      %{
        user_name: "João Pereira",
        action_type: "exclusão de conta",
        confirmation_link: "https://deeperhub.com/confirmar/xyz789",
        cancel_link: "https://deeperhub.com/cancelar/xyz789",
        expires_in_hours: 48
      },
      [use_queue: true, priority: :high]
    )
    
    IO.puts("Resultado: #{inspect(resultado)}")
    
    # Aguarda um pouco para o processamento da fila
    Process.sleep(2000)
  end
  
  defp teste_novo_dispositivo do
    IO.puts("\n--- Testando email de alerta de novo dispositivo ---")
    
    resultado = Mail.send_email(
      @test_email,
      "Alerta de Segurança: Login em Novo Dispositivo",
      :new_device_login,
      %{
        user_name: "Ana Costa",
        device_info: %{
          browser: "Firefox 97.0",
          os: "macOS 12.2.1",
          ip: "201.45.78.90",
          location: "Rio de Janeiro, Brasil"
        },
        login_time: "#{Calendar.strftime(DateTime.utc_now(), "%d/%m/%Y às %H:%M:%S")}",
        security_link: "https://deeperhub.com/seguranca/dispositivos"
      },
      [use_queue: true, priority: :high]
    )
    
    IO.puts("Resultado: #{inspect(resultado)}")
    
    # Aguarda um pouco para o processamento da fila
    Process.sleep(2000)
  end
  
  defp teste_notificacao_seguranca do
    IO.puts("\n--- Testando email de notificação de segurança avançada ---")
    
    # Testa diferentes severidades
    ["baixa", "média", "alta"]
    |> Enum.each(fn severity ->
      IO.puts("  Testando severidade: #{severity}")
      
      resultado = Mail.send_email(
        @test_email,
        "Notificação de Segurança: Tentativas de Acesso Suspeitas",
        :security_notification,
        %{
          user_name: "Carlos Mendes",
          event_type: "Múltiplas tentativas de login malsucedidas",
          event_details: %{
            description: "Detectamos várias tentativas de login malsucedidas em sua conta",
            location: "Localização desconhecida",
            ip: "45.67.89.123"
          },
          event_time: "#{Calendar.strftime(DateTime.utc_now(), "%d/%m/%Y às %H:%M:%S")}",
          security_link: "https://deeperhub.com/seguranca/atividade",
          severity: severity,
          recommendations: [
            "Altere sua senha imediatamente",
            "Ative a autenticação em duas etapas",
            "Verifique os dispositivos conectados à sua conta"
          ]
        },
        [use_queue: true, priority: (if severity == "alta", do: :high, else: :normal)]
      )
      
      IO.puts("  Resultado: #{inspect(resultado)}")
    end)
    
    # Aguarda um pouco para o processamento da fila
    Process.sleep(2000)
  end
  
  defp teste_atualizacao_sistema do
    IO.puts("\n--- Testando email de atualização do sistema ---")
    
    resultado = Mail.send_email(
      @test_email,
      "Novidades do DeeperHub: Versão 2.5 disponível",
      :system_update,
      %{
        user_name: "Usuário DeeperHub",
        update_type: "nova versão",
        update_title: "DeeperHub v2.5 - Melhorias de Segurança e Novos Recursos",
        update_details: "Temos o prazer de anunciar a disponibilidade da versão 2.5 do DeeperHub, trazendo importantes melhorias de segurança e novos recursos solicitados pela comunidade.",
        update_date: "#{Calendar.strftime(DateTime.utc_now(), "%d/%m/%Y")}",
        new_features: [
          "Novo painel de análise de dados com visualizações avançadas",
          "Integração com serviços de armazenamento em nuvem",
          "Melhorias na interface de usuário para maior produtividade"
        ],
        fixed_issues: [
          "Correção de vulnerabilidade de segurança na API",
          "Resolução de problemas de desempenho em grandes conjuntos de dados",
          "Correção de erros na exportação de relatórios"
        ],
        action_link: "https://deeperhub.com/atualizacoes/v2.5",
        action_text: "Ver todas as novidades"
      },
      [use_queue: true, priority: :low]
    )
    
    IO.puts("Resultado: #{inspect(resultado)}")
    
    # Teste com janela de manutenção
    resultado2 = Mail.send_email(
      @test_email,
      "Manutenção Programada do DeeperHub",
      :system_update,
      %{
        user_name: "Usuário DeeperHub",
        update_type: "manutenção",
        update_title: "Manutenção Programada do Sistema",
        update_details: "Informamos que realizaremos uma manutenção programada em nossos servidores para implementar melhorias de infraestrutura.",
        update_date: "#{Calendar.strftime(DateTime.utc_now(), "%d/%m/%Y")}",
        maintenance_window: "Dia 25/05/2025, das 23:00 às 03:00 (Horário de Brasília)",
        action_link: "https://deeperhub.com/status",
        action_text: "Verificar status do sistema"
      },
      [use_queue: true, priority: :normal]
    )
    
    IO.puts("Resultado (manutenção): #{inspect(resultado2)}")
    
    # Aguarda um pouco para o processamento da fila
    Process.sleep(2000)
  end
  
  defp exibir_estatisticas_fila do
    IO.puts("\n--- Estatísticas da Fila ---")
    
    stats = Queue.get_stats()
    
    IO.puts("Total de emails: #{stats.total}")
    IO.puts("Pendentes: #{stats.pending}")
    IO.puts("Em processamento: #{stats.processing}")
    IO.puts("Enviados: #{stats.sent}")
    IO.puts("Falhas: #{stats.failed}")
    IO.puts("Prioridade alta: #{stats.high_priority}")
    IO.puts("Prioridade normal: #{stats.normal_priority}")
    IO.puts("Prioridade baixa: #{stats.low_priority}")
  end
  
  defp confirmar_continuacao do
    IO.puts("\nDeseja continuar? (s/N)")
    resposta = IO.gets("") |> String.trim() |> String.downcase()
    resposta == "s"
  end
end

# Executa o teste
DeeperHub.MailTest.run()
