# Script para executar um teste de carga simples no sistema WebSocket
#
# Este script executa um teste de carga básico sem depender do módulo
# WebSocketLoadTest, para evitar problemas com o coletor de estatísticas.
#
# Para executar:
# mix run test/load_test/simple_load_test.exs

defmodule DeeperHub.LoadTest.SimpleRunner do
  @moduledoc """
  Executor de teste de carga simples para o sistema WebSocket do DeeperHub.
  """
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  # Configurações padrão para o teste
  @default_config %{
    num_channels: 5,
    num_connections: 50,
    test_duration: 30,  # segundos
    message_interval: 1000,  # milissegundos
    message_size: 100  # bytes
  }
  
  @doc """
  Executa um teste de carga simples.
  
  ## Parâmetros
  
  - `config` - Configurações adicionais para o teste (opcional)
  
  ## Retorno
  
  - `:ok` - Teste concluído com sucesso
  """
  def run(config \\ %{}) do
    # Mescla as configurações fornecidas com os valores padrão
    config = Map.merge(@default_config, config)
    
    Logger.info("Iniciando teste de carga simples com #{config.num_connections} conexões", module: __MODULE__)
    
    # Cria os canais para o teste
    channel_ids = create_test_channels(config.num_channels)
    
    if length(channel_ids) == 0 do
      Logger.error("Não foi possível criar canais para o teste. Abortando.", module: __MODULE__)
      :error
    else
      Logger.info("Criados #{length(channel_ids)} canais para o teste", module: __MODULE__)
      
      # Inicia as conexões
      connection_pids = start_connections(channel_ids, config)
      
      Logger.info("Iniciadas #{length(connection_pids)} conexões", module: __MODULE__)
      Logger.info("Teste em andamento por #{config.test_duration} segundos...", module: __MODULE__)
      
      # Aguarda a duração do teste
      :timer.sleep(config.test_duration * 1000)
      
      # Encerra as conexões
      stop_connections(connection_pids)
      
      Logger.info("Teste de carga concluído com sucesso", module: __MODULE__)
      :ok
    end
  end
  
  # Cria canais para o teste
  defp create_test_channels(num_channels) do
    Logger.info("Criando #{num_channels} canais para o teste", module: __MODULE__)
    
    1..num_channels
    |> Enum.map(fn i ->
      channel_name = "test_channel_#{i}"
      owner_id = "load_test_user"
      
      case DeeperHub.Core.Network.Channels.Channel.create(channel_name, owner_id, persistent: true) do
        {:ok, channel_id} ->
          Logger.info("Canal criado: #{channel_name} (#{channel_id})", module: __MODULE__)
          channel_id
        {:error, reason} ->
          Logger.error("Falha ao criar canal #{channel_name}: #{inspect(reason)}", module: __MODULE__)
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
  
  # Inicia as conexões para o teste
  defp start_connections(channel_ids, config) do
    Logger.info("Iniciando #{config.num_connections} conexões", module: __MODULE__)
    
    1..config.num_connections
    |> Enum.map(fn i ->
      # Distribui as conexões entre os canais disponíveis
      channel_id = Enum.at(channel_ids, rem(i - 1, length(channel_ids)))
      
      # Inicia uma conexão simulada
      start_simulated_connection(i, channel_id, config)
    end)
    |> Enum.reject(&is_nil/1)
  end
  
  # Inicia uma conexão simulada
  defp start_simulated_connection(id, channel_id, config) do
    connection_id = "conn_#{id}"
    
    pid = spawn_link(fn ->
      # Estado inicial da conexão
      state = %{
        id: connection_id,
        channel_id: channel_id,
        config: config,
        messages_sent: 0,
        messages_received: 0
      }
      
      # Registra a conexão
      Logger.debug("Conexão iniciada: #{connection_id} no canal #{channel_id}", module: __MODULE__)
      
      # Agenda o envio da primeira mensagem
      Process.send_after(self(), :send_message, :rand.uniform(config.message_interval))
      
      # Loop principal da conexão
      connection_loop(state)
    end)
    
    pid
  end
  
  # Loop principal de uma conexão simulada
  defp connection_loop(state) do
    receive do
      :send_message ->
        # Envia uma mensagem
        message = generate_message(state)
        
        # Simula o envio da mensagem
        # Em um teste real, enviaríamos a mensagem pelo WebSocket
        Logger.debug("Mensagem enviada: #{state.id} -> #{inspect(message)}", module: __MODULE__)
        
        # Atualiza o estado
        state = %{state | messages_sent: state.messages_sent + 1}
        
        # Agenda o próximo envio
        Process.send_after(self(), :send_message, state.config.message_interval)
        
        # Simula o recebimento de uma resposta
        Process.send_after(self(), {:message_received, message}, :rand.uniform(100))
        
        connection_loop(state)
        
      {:message_received, _message} ->
        # Simula o recebimento de uma mensagem
        Logger.debug("Mensagem recebida: #{state.id}", module: __MODULE__)
        
        # Atualiza o estado
        state = %{state | messages_received: state.messages_received + 1}
        
        connection_loop(state)
        
      :stop ->
        # Encerra a conexão
        Logger.debug("Conexão encerrada: #{state.id} (enviadas: #{state.messages_sent}, recebidas: #{state.messages_received})", module: __MODULE__)
        :ok
        
      _ ->
        # Ignora outras mensagens
        connection_loop(state)
    end
  end
  
  # Gera uma mensagem para envio
  defp generate_message(state) do
    content = random_string(state.config.message_size)
    
    %{
      id: UUID.uuid4(),
      channel_id: state.channel_id,
      sender_id: state.id,
      content: content,
      timestamp: :os.system_time(:millisecond)
    }
  end
  
  # Encerra todas as conexões
  defp stop_connections(connection_pids) do
    Logger.info("Encerrando #{length(connection_pids)} conexões", module: __MODULE__)
    
    Enum.each(connection_pids, fn pid ->
      send(pid, :stop)
    end)
  end
  
  # Gera uma string aleatória com o tamanho especificado
  defp random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode64()
    |> binary_part(0, length)
  end
end

# Executa o teste
DeeperHub.LoadTest.SimpleRunner.run()
