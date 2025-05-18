defmodule Deeper_Hub.Core.Supervisor do
  @moduledoc """
  Supervisor principal para os componentes do Core.

  Este supervisor é responsável por iniciar e supervisionar os componentes
  centrais da aplicação, como cache e métricas.
  """

  use Supervisor

  # Importamos o módulo Cachex.Spec para usar a função hook
  import Cachex.Spec

  alias Deeper_Hub.Core.Logger

  @doc """
  Inicia o supervisor.

  ## Parâmetros

    - `opts`: Opções para o supervisor

  ## Retorno

    - `{:ok, pid}` se o supervisor for iniciado com sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_link(opts \\ []) do
    Logger.info("Iniciando supervisor do Core", %{module: __MODULE__})
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Inicializa o supervisor com os componentes necessários.

  ## Parâmetros

    - `opts`: Opções para o supervisor

  ## Retorno

    - `{:ok, {supervisor_opts, children}}` com as opções do supervisor e os filhos
  """
  @impl true
  def init(_opts) do
    Logger.debug("Inicializando componentes do Core", %{module: __MODULE__})

    children = [
      # Inicia o cache com estatísticas habilitadas
      {Cachex, name: Deeper_Hub.Core.Cache.cache_name(),
       opts: [
         # Configura a expiração padrão para entradas no cache
         expiration: [
           default: :timer.minutes(10),
           interval: :timer.minutes(1)
         ],
         # Habilita estatísticas usando nosso hook personalizado
         hooks: [
           hook(module: Deeper_Hub.Core.Cache.StatsHook)
         ]
       ]
      },

      # Inicia o serviço de blacklist de tokens
      Deeper_Hub.Core.WebSockets.Auth.TokenBlacklist,

      # Inicia o repórter de métricas
      Deeper_Hub.Core.Metrics.Reporter,

      # Inicia um worker para configurar o EventBus
      %{
        id: :event_bus_init_task,
        start: {Task, :start_link, [fn -> Deeper_Hub.Core.EventBus.init() end]},
        restart: :temporary
      },

      # Inicia o ConnectionManager para gerenciar conexões WebSocket
      Deeper_Hub.Core.Communications.ConnectionManager,

      # Inicia o MessageManager para gerenciar mensagens diretas
      Deeper_Hub.Core.Communications.Messages.MessageManager,

      # Inicia o ChannelManager para gerenciar canais
      Deeper_Hub.Core.Communications.Channels.ChannelManager,

      # Inicia o supervisor do WebSocket
      {Deeper_Hub.Core.WebSockets.WebSocketSupervisor, [port: 4000]},

      # Inicia um worker para criar as tabelas do banco de dados apenas se necessário
      %{
        id: :db_tables_init_task,
        start: {Task, :start_link, [fn ->
          # Verifica se as tabelas já existem antes de tentar criá-las
          alias Deeper_Hub.Core.Data.DBConnection.Connection

          # Verifica se a tabela de mensagens existe
          messages_exists = Connection.query_exists?("messages")
          unless messages_exists do
            Deeper_Hub.Core.Communications.Messages.MessageStorage.create_table_if_not_exists()
          end

          # Verifica se a tabela de canais existe
          channels_exists = Connection.query_exists?("channels")
          unless channels_exists do
            Deeper_Hub.Core.Communications.Channels.ChannelStorage.create_tables_if_not_exist()
          end
        end]},
        restart: :temporary
      }
    ]

    # Configura o supervisor para reiniciar os filhos individualmente
    Supervisor.init(children, strategy: :one_for_one)
  end
end
