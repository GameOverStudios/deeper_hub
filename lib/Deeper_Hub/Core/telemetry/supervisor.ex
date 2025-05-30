defmodule DeeperHub.Core.Telemetry.Supervisor do
  @moduledoc """
  Supervisor para o subsistema de telemetria do DeeperHub.
  
  Este módulo é responsável por iniciar e supervisionar todos os processos
  relacionados à telemetria, incluindo os adaptadores para diferentes
  subsistemas e os exportadores de métricas.
  """
  
  use Supervisor
  
  alias DeeperHub.Core.Telemetry.Initializer
  
  require Logger
  
  @doc """
  Inicia o supervisor de telemetria.
  
  ## Parâmetros
  
  - `opts` - Opções de configuração para o sistema de telemetria.
  
  ## Retorno
  
  - `{:ok, pid}` - Se o supervisor for iniciado com sucesso.
  - `{:error, reason}` - Se ocorrer um erro durante a inicialização.
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Logger.info("[DeeperHub.Core.Telemetry.Supervisor] Iniciando supervisor do subsistema de telemetria...")
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Inicializa o supervisor e seus processos filhos.
  
  ## Parâmetros
  
  - `opts` - Opções de configuração para o sistema de telemetria.
  
  ## Retorno
  
  - `{:ok, {:supervisor.sup_flags(), [supervisor.child_spec()]}}` - Especificação do supervisor.
  """
  @impl true
  def init(opts) do
    # Determinar quais adaptadores e exportadores devem ser habilitados
    # baseado nas configurações da aplicação
    enabled_adapters = obter_adaptadores_habilitados()
    enabled_exporters = obter_exportadores_habilitados()
    
    # Opções para o inicializador de telemetria
    telemetry_opts = [
      enabled_adapters: enabled_adapters,
      exporters: enabled_exporters,
      telemetry_prefix: "deeper_hub"
    ]
    
    # Mesclar as opções padrão com as opções fornecidas
    telemetry_opts = Keyword.merge(telemetry_opts, opts)
    
    # Inicializar o sistema de telemetria
    case Initializer.setup(telemetry_opts) do
      {:ok, %{adapters: adapters, exporters: exporters}} ->
        Logger.info("[DeeperHub.Core.Telemetry.Supervisor] Sistema de telemetria inicializado com sucesso. " <>
                   "Adaptadores: #{inspect(Map.keys(adapters))}, Exportadores: #{inspect(Map.keys(exporters))}")
        
        # Definir estratégia de supervisão
        # Como o Initializer já iniciou os processos, não precisamos definir filhos aqui
        # No entanto, o supervisor ainda é útil para gerenciar o ciclo de vida do subsistema
        children = []
        
        Supervisor.init(children, strategy: :one_for_one)
        
      {:error, reason} ->
        Logger.error("[DeeperHub.Core.Telemetry.Supervisor] Falha ao inicializar sistema de telemetria: #{inspect(reason)}")
        # Iniciar supervisor vazio, sem processos filhos
        Supervisor.init([], strategy: :one_for_one)
    end
  end
  
  @doc """
  Desativa o sistema de telemetria.
  
  ## Retorno
  
  - `:ok` - Se o sistema for desativado com sucesso.
  """
  @spec shutdown() :: :ok
  def shutdown do
    # Encerrar o inicializador e seus processos
    Initializer.teardown()
    
    # Tentar encerrar o supervisor (se estiver em execução)
    try do
      Supervisor.stop(__MODULE__, :normal)
    catch
      :exit, {:noproc, _} -> :ok
    end
    
    Logger.info("[DeeperHub.Core.Telemetry.Supervisor] Subsistema de telemetria encerrado")
    :ok
  end
  
  # Funções privadas auxiliares
  
  @spec obter_adaptadores_habilitados() :: list(atom())
  defp obter_adaptadores_habilitados do
    # Em uma implementação real, isso seria obtido da configuração da aplicação
    # Por padrão, habilitar todos os adaptadores
    [:cache, :http, :network, :security, :database]
  end
  
  @spec obter_exportadores_habilitados() :: list(atom())
  defp obter_exportadores_habilitados do
    # Em uma implementação real, isso seria obtido da configuração da aplicação
    # Por padrão, não habilitar nenhum exportador
    []
  end
end
