defmodule Deeper_Hub.Core.CircuitBreaker.Registry do
  @moduledoc """
  Gerencia o registro e acesso às instâncias de CircuitBreaker.
  
  Este módulo é responsável por:
  - Registrar novos circuit breakers
  - Localizar instâncias existentes
  - Fornecer informações sobre os circuit breakers registrados
  """
  
  use GenServer
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.CircuitBreaker.Instance
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  
  # Nome do processo GenServer
  @server __MODULE__
  
  # API Pública
  
  @doc """
  Inicia o GenServer do registro.
  
  ## Parâmetros
  
    - `opts`: Opções para o GenServer
  
  ## Retorno
  
    - `{:ok, pid}` se o processo for iniciado com sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, [name: @server] ++ opts)
  end
  
  @doc """
  Registra um novo circuit breaker.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `config`: Configurações específicas para este circuit breaker
  
  ## Retorno
  
    - `{:ok, pid}` se o circuit breaker for registrado com sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec register(atom(), map()) :: {:ok, pid()} | {:error, term()}
  def register(service_name, config \\ %{}) do
    GenServer.call(@server, {:register, service_name, config})
  end
  
  @doc """
  Retorna o estado atual de um circuit breaker.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço protegido pelo circuit breaker
  
  ## Retorno
  
    - `{:ok, state}` onde `state` é `:closed`, `:open` ou `:half_open`
    - `{:error, :not_found}` se o circuit breaker não existir
  """
  @spec state(atom()) :: {:ok, atom()} | {:error, :not_found}
  def state(service_name) do
    try do
      Instance.state(service_name)
    rescue
      _ -> {:error, :not_found}
    catch
      :exit, _ -> {:error, :not_found}
    end
  end
  
  @doc """
  Reseta um circuit breaker para o estado fechado.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço protegido pelo circuit breaker
  
  ## Retorno
  
    - `:ok` se o circuit breaker for resetado com sucesso
    - `{:error, :not_found}` se o circuit breaker não existir
  """
  @spec reset(atom()) :: :ok | {:error, :not_found}
  def reset(service_name) do
    try do
      Instance.reset(service_name)
    rescue
      _ -> {:error, :not_found}
    catch
      :exit, _ -> {:error, :not_found}
    end
  end
  
  @doc """
  Atualiza a configuração de um circuit breaker.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `config`: Novas configurações
  
  ## Retorno
  
    - `:ok` se a configuração for atualizada com sucesso
    - `{:error, :not_found}` se o circuit breaker não existir
  """
  @spec update_config(atom(), map()) :: :ok | {:error, :not_found}
  def update_config(service_name, config) do
    try do
      Instance.update_config(service_name, config)
    rescue
      _ -> {:error, :not_found}
    catch
      :exit, _ -> {:error, :not_found}
    end
  end
  
  @doc """
  Lista todos os circuit breakers registrados.
  
  ## Retorno
  
    - `{:ok, list}` com a lista de nomes de serviços e seus estados
  """
  @spec list_all() :: {:ok, list({atom(), atom()})}
  def list_all do
    GenServer.call(@server, :list_all)
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init(:ok) do
    Logger.info("Iniciando registro de circuit breakers", %{
      module: __MODULE__
    })
    
    # Inicializa o adaptador de armazenamento
    storage_adapter = Application.get_env(
      :deeper_hub, 
      [:core, :circuit_breaker, :storage_adapter], 
      Deeper_Hub.Core.CircuitBreaker.MemoryStorage
    )
    
    # Inicializa o armazenamento
    :ok = storage_adapter.initialize()
    
    # Tenta restaurar circuit breakers previamente registrados
    restore_circuit_breakers(storage_adapter)
    
    {:ok, %{storage_adapter: storage_adapter}}
  end
  
  @impl true
  def handle_call({:register, service_name, config}, _from, state) do
    Logger.info("Registrando circuit breaker", %{
      module: __MODULE__,
      service_name: service_name,
      config: config
    })
    
    # Verifica se o circuit breaker já existe
    case find_circuit_breaker(service_name) do
      {:ok, pid} ->
        # Já existe, atualiza a configuração
        :ok = Instance.update_config(service_name, config)
        
        Logger.info("Circuit breaker já existente, configuração atualizada", %{
          module: __MODULE__,
          service_name: service_name
        })
        
        {:reply, {:ok, pid}, state}
        
      {:error, :not_found} ->
        # Não existe, cria um novo
        case Instance.start_link(service_name, config, []) do
          {:ok, pid} ->
            Logger.info("Circuit breaker registrado com sucesso", %{
              module: __MODULE__,
              service_name: service_name,
              pid: inspect(pid)
            })
            
            # Registra métrica de circuit breaker criado
            Metrics.increment("deeper_hub.core.circuit_breaker.created", %{
              service_name: service_name
            })
            
            {:reply, {:ok, pid}, state}
            
          {:error, reason} = error ->
            Logger.error("Falha ao registrar circuit breaker", %{
              module: __MODULE__,
              service_name: service_name,
              reason: reason
            })
            
            {:reply, error, state}
        end
    end
  end
  
  @impl true
  def handle_call(:list_all, _from, state) do
    # Obtém todos os circuit breakers registrados
    circuit_breakers = Registry.select(
      Deeper_Hub.Core.CircuitBreaker.InstanceRegistry,
      [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}]
    )
    
    # Obtém o estado de cada circuit breaker
    result = Enum.map(circuit_breakers, fn {service_name, _pid} ->
      case state(service_name) do
        {:ok, cb_state} -> {service_name, cb_state}
        _ -> {service_name, :unknown}
      end
    end)
    
    Logger.debug("Listando circuit breakers", %{
      module: __MODULE__,
      count: length(result)
    })
    
    {:reply, {:ok, result}, state}
  end
  
  # Funções privadas
  
  # Restaura circuit breakers previamente registrados
  defp restore_circuit_breakers(storage_adapter) do
    case storage_adapter.list_all() do
      {:ok, service_names} ->
        Logger.info("Restaurando #{length(service_names)} circuit breakers", %{
          module: __MODULE__
        })
        
        # Inicia cada circuit breaker
        Enum.each(service_names, fn service_name ->
          # Carrega o estado e metadados
          case storage_adapter.load_state(service_name) do
            {:ok, {_state, _metadata}} ->
              # Registra o circuit breaker com configurações padrão
              # O estado será carregado pelo próprio Instance ao iniciar
              register(service_name, %{})
              
            _ ->
              Logger.warning("Falha ao carregar estado do circuit breaker", %{
                module: __MODULE__,
                service_name: service_name
              })
          end
        end)
        
      _ ->
        Logger.info("Nenhum circuit breaker para restaurar", %{
          module: __MODULE__
        })
    end
  end
  
  # Encontra um circuit breaker pelo nome do serviço
  defp find_circuit_breaker(service_name) do
    case Registry.lookup(Deeper_Hub.Core.CircuitBreaker.InstanceRegistry, service_name) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end
end
