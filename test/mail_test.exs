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
