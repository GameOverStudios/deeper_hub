defmodule Deeper_Hub.Core.Communications.CommunicationsTest do
  @moduledoc """
  Testes para o sistema de comunicação.
  
  Este módulo contém testes para verificar o funcionamento do sistema de comunicação,
  incluindo mensagens diretas e canais.
  """
  
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Communications.ConnectionManager
  alias Deeper_Hub.Core.Communications.Messages.MessageManager
  alias Deeper_Hub.Core.Communications.Channels.ChannelManager
  
  # Configuração para os testes
  setup do
    # Inicia os processos necessários para os testes ou obtém os PIDs existentes
    conn_pid = case Process.whereis(ConnectionManager) do
      nil -> 
        {:ok, pid} = ConnectionManager.start_link()
        pid
      pid -> pid
    end
    
    msg_pid = case Process.whereis(MessageManager) do
      nil -> 
        {:ok, pid} = MessageManager.start_link()
        pid
      pid -> pid
    end
    
    channel_pid = case Process.whereis(ChannelManager) do
      nil -> 
        {:ok, pid} = ChannelManager.start_link()
        pid
      pid -> pid
    end
    
    # Limpa qualquer estado anterior
    :sys.replace_state(ConnectionManager, fn _ -> %{users: %{}} end)
    :sys.replace_state(MessageManager, fn _ -> %{messages: %{}} end)
    :sys.replace_state(ChannelManager, fn _ -> %{channels: %{}, user_subscriptions: %{}} end)
    
    # Retorna os PIDs para uso nos testes
    %{
      conn_pid: conn_pid,
      msg_pid: msg_pid,
      channel_pid: channel_pid
    }
  end
  
  describe "ConnectionManager" do
    test "registra e remove conexões de usuários" do
      # Cria um processo de teste para simular uma conexão WebSocket
      test_pid = spawn(fn -> receive do _ -> :ok end end)
      
      # Registra o usuário
      assert :ok = ConnectionManager.register("user1", test_pid)
      
      # Verifica se o usuário está registrado
      assert {:ok, ^test_pid} = ConnectionManager.get_user_connection("user1")
      
      # Remove o usuário
      assert :ok = ConnectionManager.unregister("user1")
      
      # Verifica se o usuário foi removido
      assert {:error, :user_not_found} = ConnectionManager.get_user_connection("user1")
    end
    
    test "envia mensagem para usuário" do
      # Cria um processo de teste que recebe mensagens
      test_pid = self()
      
      # Registra o usuário
      assert :ok = ConnectionManager.register("user1", test_pid)
      
      # Envia uma mensagem para o usuário
      message = %{type: "test", payload: %{message: "Hello"}}
      assert :ok = ConnectionManager.send_to_user("user1", message)
      
      # Verifica se a mensagem foi recebida
      assert_receive {:send, ^message}, 1000
    end
    
    test "falha ao enviar mensagem para usuário inexistente" do
      # Tenta enviar uma mensagem para um usuário que não existe
      message = %{type: "test", payload: %{message: "Hello"}}
      assert {:error, :user_not_found} = ConnectionManager.send_to_user("nonexistent", message)
    end
  end
  
  describe "MessageManager" do
    test "envia e recupera mensagens" do
      # Cria um processo de teste para simular uma conexão WebSocket
      test_pid = spawn(fn -> receive do _ -> :ok end end)
      
      # Registra os usuários
      ConnectionManager.register("sender", test_pid)
      ConnectionManager.register("recipient", test_pid)
      
      # Envia uma mensagem
      {:ok, message_id} = MessageManager.send_message("sender", "recipient", "Hello!", %{priority: "high"})
      
      # Verifica se a mensagem foi armazenada corretamente
      {:ok, message} = MessageManager.get_message(message_id)
      assert message.sender_id == "sender"
      assert message.recipient_id == "recipient"
      assert message.content == "Hello!"
      assert message.metadata.priority == "high"
      assert message.read == false
      
      # Marca a mensagem como lida
      :ok = MessageManager.mark_as_read(message_id, "recipient")
      
      # Verifica se a mensagem foi marcada como lida
      {:ok, updated_message} = MessageManager.get_message(message_id)
      assert updated_message.read == true
      assert updated_message.read_at != nil
    end
    
    test "obtém conversa entre usuários" do
      # Envia várias mensagens entre dois usuários
      {:ok, _} = MessageManager.send_message("user1", "user2", "Mensagem 1", %{})
      {:ok, _} = MessageManager.send_message("user2", "user1", "Mensagem 2", %{})
      {:ok, _} = MessageManager.send_message("user1", "user2", "Mensagem 3", %{})
      
      # Obtém a conversa
      {:ok, messages} = MessageManager.get_conversation("user1", "user2", 10, 0)
      
      # Verifica se todas as mensagens foram recuperadas
      assert length(messages) == 3
      
      # Verifica se as mensagens estão ordenadas corretamente (mais recentes primeiro)
      [msg1, msg2, msg3] = messages
      assert msg1.content == "Mensagem 3"
      assert msg2.content == "Mensagem 2"
      assert msg3.content == "Mensagem 1"
    end
    
    test "obtém conversas recentes" do
      # Envia mensagens para diferentes usuários
      {:ok, _} = MessageManager.send_message("main_user", "user1", "Conversa 1", %{})
      {:ok, _} = MessageManager.send_message("main_user", "user2", "Conversa 2", %{})
      {:ok, _} = MessageManager.send_message("user3", "main_user", "Conversa 3", %{})
      
      # Obtém as conversas recentes
      {:ok, conversations} = MessageManager.get_recent_conversations("main_user", 10)
      
      # Verifica se todas as conversas foram recuperadas
      assert length(conversations) == 3
      
      # Verifica se as conversas contêm as informações corretas
      user_ids = Enum.map(conversations, fn conv -> conv.user_id end)
      assert "user1" in user_ids
      assert "user2" in user_ids
      assert "user3" in user_ids
    end
  end
  
  describe "ChannelManager" do
    test "cria e gerencia canais" do
      # Cria um canal
      {:ok, channel_id} = ChannelManager.create_channel("test-channel", "creator", %{description: "Test channel"})
      
      # Verifica se o canal foi criado corretamente
      {:ok, channel_info} = ChannelManager.get_channel_info("test-channel")
      assert channel_info.id == channel_id
      assert channel_info.name == "test-channel"
      assert channel_info.creator_id == "creator"
      assert channel_info.metadata.description == "Test channel"
      
      # Lista os canais disponíveis
      {:ok, channels} = ChannelManager.list_channels()
      assert length(channels) == 1
      assert hd(channels).name == "test-channel"
      
      # Inscreve um usuário no canal
      :ok = ChannelManager.subscribe("test-channel", "user1")
      
      # Verifica se o usuário está inscrito
      {:ok, subscribers} = ChannelManager.list_subscribers("test-channel")
      assert "user1" in subscribers
      assert "creator" in subscribers # O criador é automaticamente inscrito
      
      # Cancela a inscrição do usuário
      :ok = ChannelManager.unsubscribe("test-channel", "user1")
      
      # Verifica se o usuário foi removido
      {:ok, updated_subscribers} = ChannelManager.list_subscribers("test-channel")
      refute "user1" in updated_subscribers
      assert "creator" in updated_subscribers
    end
    
    test "publica mensagens em canais" do
      # Cria um processo de teste para simular uma conexão WebSocket
      test_pid = self()
      
      # Cria um canal
      {:ok, _} = ChannelManager.create_channel("announcement", "admin", %{})
      
      # Inscreve usuários no canal
      :ok = ChannelManager.subscribe("announcement", "user1")
      :ok = ChannelManager.subscribe("announcement", "user2")
      
      # Registra os usuários no ConnectionManager
      ConnectionManager.register("user1", test_pid)
      ConnectionManager.register("user2", test_pid)
      
      # Publica uma mensagem no canal
      {:ok, _message_id, recipient_count} = ChannelManager.publish("announcement", "admin", "Anúncio importante", %{})
      
      # Verifica se a mensagem foi enviada para todos os inscritos
      assert recipient_count == 2
      
      # Verifica se recebemos as mensagens
      assert_receive {:send, %{type: "channel.message", payload: %{channel_name: "announcement"}}}, 1000
      assert_receive {:send, %{type: "channel.message", payload: %{channel_name: "announcement"}}}, 1000
    end
  end
end
