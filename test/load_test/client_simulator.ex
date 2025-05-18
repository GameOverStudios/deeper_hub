defmodule DeeperHub.LoadTest.ClientSimulator do
  @moduledoc """
  Simulador de cliente WebSocket para testes de carga.
  
  Este módulo implementa um cliente WebSocket real que se conecta ao servidor
  DeeperHub para testes de carga. Ele usa a biblioteca Gun para estabelecer
  conexões WebSocket reais e enviar/receber mensagens.
  """
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Inicia um cliente WebSocket que se conecta ao servidor especificado.
  
  ## Parâmetros
  
  - `config` - Configuração do cliente
  - `channel_id` - ID do canal para se conectar
  - `client_id` - ID único do cliente
  - `parent` - PID do processo pai para enviar atualizações
  
  ## Retorno
  
  - `{:ok, pid}` - Cliente iniciado com sucesso
  - `{:error, reason}` - Falha ao iniciar o cliente
  """
  def start_link(config, channel_id, client_id, parent) do
    pid = spawn_link(fn ->
      # Inicializa o estado do cliente
      state = %{
        config: config,
        channel_id: channel_id,
        client_id: client_id,
        parent: parent,
        gun_pid: nil,
        stream_ref: nil,
        connected: false,
        messages_sent: 0,
        messages_received: 0,
        last_message_time: nil
      }
      
      # Conecta ao servidor WebSocket
      case connect(state) do
        {:ok, new_state} ->
          # Inicia o loop do cliente
          client_loop(new_state)
          
        {:error, reason} ->
          # Notifica o pai sobre a falha
          send(parent, {:client_error, client_id, reason})
      end
    end)
    
    {:ok, pid}
  end
  
  # Conecta ao servidor WebSocket
  defp connect(state) do
    host = String.to_charlist(state.config.host)
    port = state.config.port
    
    # Opções para a conexão Gun
    opts = %{
      protocols: [:http],
      transport: :tcp,
      transport_opts: [
        nodelay: true,
        keepalive: true
      ],
      http_opts: %{
        keepalive: :infinity
      }
    }
    
    # Abre a conexão HTTP
    case :gun.open(host, port, opts) do
      {:ok, pid} ->
        # Aguarda a conexão ser estabelecida
        case :gun.await_up(pid, 5000) do
          {:ok, _protocol} ->
            # Constrói o caminho com os parâmetros
            path = "#{state.config.path}?channel=#{state.channel_id}&client_id=#{state.client_id}"
            
            # Inicia o upgrade para WebSocket
            stream_ref = :gun.ws_upgrade(pid, path)
            
            # Aguarda a resposta do upgrade
            receive do
              {:gun_upgrade, ^pid, ^stream_ref, ["websocket"], _headers} ->
                # Upgrade bem-sucedido
                Logger.debug("Cliente #{state.client_id} conectado ao WebSocket", module: __MODULE__)
                
                # Notifica o pai sobre o sucesso
                send(state.parent, {:client_connected, state.client_id})
                
                # Agenda o envio da primeira mensagem
                if state.config.message_rate > 0 do
                  interval = trunc(1000 / state.config.message_rate)
                  Process.send_after(self(), :send_message, interval)
                end
                
                # Atualiza o estado
                {:ok, %{state | gun_pid: pid, stream_ref: stream_ref, connected: true}}
                
              {:gun_response, ^pid, ^stream_ref, _, status, _headers} ->
                # Resposta HTTP não esperada
                Logger.error("Falha no upgrade WebSocket para o cliente #{state.client_id}: status #{status}", module: __MODULE__)
                :gun.close(pid)
                {:error, {:http_error, status}}
                
              {:gun_error, ^pid, ^stream_ref, reason} ->
                # Erro no upgrade
                Logger.error("Erro no upgrade WebSocket para o cliente #{state.client_id}: #{inspect(reason)}", module: __MODULE__)
                :gun.close(pid)
                {:error, reason}
            after
              5000 ->
                # Timeout no upgrade
                Logger.error("Timeout no upgrade WebSocket para o cliente #{state.client_id}", module: __MODULE__)
                :gun.close(pid)
                {:error, :upgrade_timeout}
            end
            
          {:error, reason} ->
            # Falha ao aguardar a conexão
            Logger.error("Falha ao aguardar conexão Gun para o cliente #{state.client_id}: #{inspect(reason)}", module: __MODULE__)
            :gun.close(pid)
            {:error, reason}
        end
        
      {:error, reason} ->
        # Falha ao abrir a conexão
        Logger.error("Falha ao abrir conexão Gun para o cliente #{state.client_id}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  # Loop principal do cliente
  defp client_loop(state) do
    receive do
      # Mensagem para enviar ao servidor
      :send_message when state.connected ->
        # Gera uma mensagem de teste
        message = generate_message(state)
        
        # Registra o tempo de envio
        timestamp = :os.timestamp()
        
        # Codifica a mensagem como JSON
        json = Jason.encode!(message)
        
        # Envia a mensagem WebSocket
        :gun.ws_send(state.gun_pid, {:text, json})
        
        # Notifica o pai
        send(state.parent, {:message_sent, state.client_id, timestamp})
        
        # Agenda a próxima mensagem
        if state.config.message_rate > 0 do
          interval = trunc(1000 / state.config.message_rate)
          Process.send_after(self(), :send_message, interval)
        end
        
        # Atualiza o estado
        state = %{state | 
          messages_sent: state.messages_sent + 1,
          last_message_time: timestamp
        }
        client_loop(state)
        
      # Mensagem recebida do servidor
      {:gun_ws, pid, stream_ref, {:text, data}} when pid == state.gun_pid and stream_ref == state.stream_ref ->
        # Registra o tempo de recebimento
        receive_time = :os.timestamp()
        
        # Processa a mensagem recebida
        case process_message(data, state) do
          {:ok, send_time} ->
            # Calcula a latência
            latency = timer_diff_ms(receive_time, send_time)
            
            # Notifica o pai
            send(state.parent, {:message_received, state.client_id, latency})
            
            # Atualiza o estado
            state = %{state | messages_received: state.messages_received + 1}
            client_loop(state)
            
          {:error, reason} ->
            # Notifica o pai sobre o erro
            send(state.parent, {:message_error, state.client_id, reason})
            client_loop(state)
        end
        
      # Conexão WebSocket fechada
      {:gun_down, pid, _protocol, _reason, _killed_streams} when pid == state.gun_pid ->
        # Notifica o pai
        send(state.parent, {:client_disconnected, state.client_id})
        
        # Tenta reconectar
        Logger.debug("Cliente #{state.client_id} desconectado. Tentando reconectar...", module: __MODULE__)
        
        # Fecha a conexão antiga
        :gun.close(state.gun_pid)
        
        # Tenta reconectar após um atraso
        Process.send_after(self(), :reconnect, 1000)
        
        # Atualiza o estado
        state = %{state | gun_pid: nil, stream_ref: nil, connected: false}
        client_loop(state)
        
      # Tentar reconectar
      :reconnect ->
        case connect(state) do
          {:ok, new_state} ->
            # Reconexão bem-sucedida
            client_loop(new_state)
            
          {:error, _reason} ->
            # Falha na reconexão, tenta novamente
            Process.send_after(self(), :reconnect, 5000)
            client_loop(state)
        end
        
      # Comando para parar o cliente
      :stop ->
        # Fecha a conexão se estiver aberta
        if state.connected and state.gun_pid do
          :gun.close(state.gun_pid)
        end
        
        # Envia estatísticas finais
        send(state.parent, {:client_stats, state.client_id, %{
          messages_sent: state.messages_sent,
          messages_received: state.messages_received
        }})
        
        :ok
        
      # Ignora outras mensagens
      _ ->
        client_loop(state)
    end
  end
  
  # Gera uma mensagem para enviar ao servidor
  defp generate_message(state) do
    # Gera conteúdo aleatório com o tamanho especificado
    content = random_string(state.config.message_size)
    
    # Formata a mensagem
    %{
      type: "message",
      channel_id: state.channel_id,
      client_id: state.client_id,
      content: content,
      timestamp: :os.system_time(:millisecond)
    }
  end
  
  # Processa uma mensagem recebida do servidor
  defp process_message(data, _state) do
    try do
      # Decodifica a mensagem JSON
      decoded = Jason.decode!(data)
      
      # Extrai o timestamp de envio para cálculo de latência
      send_time = 
        case decoded do
          %{"timestamp" => timestamp} when is_integer(timestamp) ->
            # Converte o timestamp para o formato de :os.timestamp()
            sec = div(timestamp, 1000)
            msec = rem(timestamp, 1000)
            {sec, msec, 0}
            
          _ ->
            # Usa o timestamp atual se não encontrar na mensagem
            :os.timestamp()
        end
      
      {:ok, send_time}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end
  
  # Gera uma string aleatória com o tamanho especificado
  defp random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode64()
    |> binary_part(0, length)
  end
  
  # Calcula a diferença entre dois timestamps em milissegundos
  defp timer_diff_ms({sec2, msec2, usec2}, {sec1, msec1, usec1}) do
    ((sec2 - sec1) * 1_000_000 + (msec2 - msec1)) / 1_000 + (usec2 - usec1) / 1_000_000
  end
end
