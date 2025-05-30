defmodule DeeperHub.Core.Telemetry.Adapters.NetworkAdapter do
  @moduledoc """
  Adaptador de telemetria para o subsistema de rede do DeeperHub.
  
  Este adaptador é responsável por coletar e relatar métricas relacionadas a:
  - Comunicação PubSub
  - Canais WebSocket
  - Gerenciamento de presença
  - Transmissão de mensagens
  """
  
  alias DeeperHub.Core.Telemetry.Reporter
  alias DeeperHub.Core.Telemetry.Metrics
  
  @doc """
  Inicializa o adaptador de telemetria para o subsistema de rede.
  
  ## Parâmetros
  
  - `opts` - Opções adicionais de configuração.
  
  ## Retorno
  
  - `{:ok, pid}` - Se o adaptador for inicializado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante a inicialização.
  
  ## Exemplos
  
      iex> DeeperHub.Core.Telemetry.Adapters.NetworkAdapter.setup()
      {:ok, #PID<0.123.0>}
  """
  @spec setup(keyword()) :: {:ok, pid()} | {:error, term()}
  def setup(opts \\ []) do
    component = :network
    
    try do
      DeeperHub.Core.Telemetry.Configurator.setup(component, opts)
    rescue
      e -> {:error, e}
    end
  end
  
  @doc """
  Relata um evento de conexão de cliente.
  
  ## Parâmetros
  
  - `client_id` - Identificador único do cliente
  - `connection_type` - Tipo de conexão (websocket, tcp, etc)
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_connection(String.t(), atom(), keyword()) :: :ok | {:error, term()}
  def report_connection(client_id, connection_type, opts \\ []) do
    Reporter.report_event([:deeper_hub, :network, :connection], %{
      client_id: client_id,
      connection_type: connection_type,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Relata um evento de desconexão de cliente.
  
  ## Parâmetros
  
  - `client_id` - Identificador único do cliente
  - `reason` - Motivo da desconexão
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_disconnection(String.t(), atom(), keyword()) :: :ok | {:error, term()}
  def report_disconnection(client_id, reason, opts \\ []) do
    Reporter.report_event([:deeper_hub, :network, :disconnection], %{
      client_id: client_id,
      reason: reason,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Relata um evento de mensagem enviada.
  
  ## Parâmetros
  
  - `channel` - Canal de comunicação
  - `message_size` - Tamanho da mensagem em bytes
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_message_sent(String.t(), integer(), keyword()) :: :ok | {:error, term()}
  def report_message_sent(channel, message_size, opts \\ []) do
    Reporter.report_event([:deeper_hub, :network, :message, :sent], %{
      channel: channel,
      message_size: message_size,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Relata um evento de alteração de presença.
  
  ## Parâmetros
  
  - `user_id` - ID do usuário
  - `status` - Novo status (online, offline, away)
  - `opts` - Opções adicionais
  
  ## Retorno
  
  - `:ok` - Se o evento for relatado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante o relato.
  """
  @spec report_presence_change(String.t(), atom(), keyword()) :: :ok | {:error, term()}
  def report_presence_change(user_id, status, opts \\ []) do
    Reporter.report_event([:deeper_hub, :network, :presence], %{
      user_id: user_id,
      status: status,
      timestamp: DateTime.utc_now()
    }, opts)
  end
  
  @doc """
  Define as métricas específicas para o subsistema de rede.
  
  ## Retorno
  
  - `list()` - Lista de métricas definidas.
  """
  @spec metrics() :: list()
  def metrics do
    Metrics.definitions("deeper_hub.network")
    |> Enum.concat([
      # Métricas específicas de rede
      Telemetry.Metrics.counter("deeper_hub.network.connection.count",
        tags: [:connection_type],
        description: "Contador de conexões estabelecidas"),
        
      Telemetry.Metrics.counter("deeper_hub.network.disconnection.count",
        tags: [:reason],
        description: "Contador de desconexões por motivo"),
        
      Telemetry.Metrics.sum("deeper_hub.network.message.sent.bytes",
        measurement: fn %{message_size: size} -> size end,
        tags: [:channel],
        description: "Total de bytes enviados por canal"),
        
      Telemetry.Metrics.last_value("deeper_hub.network.clients.connected",
        description: "Número atual de clientes conectados"),
        
      Telemetry.Metrics.distribution("deeper_hub.network.message.latency",
        unit: {:native, :millisecond},
        description: "Distribuição da latência de entrega de mensagens")
    ])
  end
end
