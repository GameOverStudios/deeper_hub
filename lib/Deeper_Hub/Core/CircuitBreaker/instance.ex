defmodule Deeper_Hub.Core.CircuitBreaker.Instance do
  @moduledoc """
  Implementa a lógica de máquina de estados do circuit breaker para um serviço específico.
  
  Este módulo é responsável por:
  - Manter o estado do circuit breaker (fechado, aberto, meio-aberto)
  - Rastrear falhas e sucessos
  - Gerenciar timeouts para tentativas de recuperação
  - Executar operações protegidas pelo circuit breaker
  """
  
  use GenServer
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Metrics.MetricsFacade, as: Metrics
  
  # Estados possíveis do circuit breaker
  @states [:closed, :open, :half_open]
  
  # Estrutura de estado do GenServer
  defmodule State do
    @moduledoc false
    defstruct [
      # Nome do serviço protegido pelo circuit breaker
      service_name: nil,
      
      # Estado atual do circuit breaker (:closed, :open, :half_open)
      current_state: :closed,
      
      # Configurações
      config: %{
        # Número de falhas para abrir o circuito
        failure_threshold: 5,
        
        # Número de sucessos em estado meio-aberto para fechar o circuito
        success_threshold: 2,
        
        # Tempo que o circuito permanece aberto antes de tentar o estado meio-aberto (ms)
        reset_timeout_ms: 60_000,
        
        # Timeout para a chamada ao serviço protegido (ms)
        call_timeout_ms: 5_000
      },
      
      # Contadores
      failure_count: 0,
      success_count: 0,
      
      # Timestamps
      opened_at: nil,
      
      # Adaptador de armazenamento
      storage_adapter: Deeper_Hub.Core.CircuitBreaker.MemoryStorage
    ]
  end
  
  # API Pública
  
  @doc """
  Inicia o GenServer para um circuit breaker específico.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `config`: Configurações específicas para este circuit breaker (opcional)
    - `opts`: Opções adicionais para o GenServer
  
  ## Retorno
  
    - `{:ok, pid}` se o processo for iniciado com sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec start_link(atom(), map(), Keyword.t()) :: GenServer.on_start()
  def start_link(service_name, config \\ %{}, opts \\ []) do
    name = via_tuple(service_name)
    GenServer.start_link(__MODULE__, {service_name, config}, [name: name] ++ opts)
  end
  
  @doc """
  Executa uma operação protegida pelo circuit breaker.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `operation_fun`: Função que realiza a operação protegida
    - `fallback_fun`: Função de fallback a ser executada se o circuito estiver aberto ou a operação falhar (opcional)
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - Resultado da função `operation_fun` ou `fallback_fun`
    - `{:error, :circuit_open}` se o circuito estiver aberto e nenhum fallback for fornecido
  """
  @spec run(atom(), function(), function() | nil, Keyword.t()) :: any()
  def run(service_name, operation_fun, fallback_fun \\ nil, opts \\ []) do
    name = via_tuple(service_name)
    GenServer.call(name, {:run, operation_fun, fallback_fun, opts})
  end
  
  @doc """
  Retorna o estado atual do circuit breaker.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço protegido pelo circuit breaker
  
  ## Retorno
  
    - `{:ok, state}` onde `state` é `:closed`, `:open` ou `:half_open`
    - `{:error, reason}` em caso de falha
  """
  @spec state(atom()) :: {:ok, atom()} | {:error, term()}
  def state(service_name) do
    name = via_tuple(service_name)
    GenServer.call(name, :get_state)
  end
  
  @doc """
  Reseta o circuit breaker para o estado fechado.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço protegido pelo circuit breaker
  
  ## Retorno
  
    - `:ok` se o circuit breaker for resetado com sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec reset(atom()) :: :ok | {:error, term()}
  def reset(service_name) do
    name = via_tuple(service_name)
    GenServer.call(name, :reset)
  end
  
  @doc """
  Atualiza a configuração do circuit breaker.
  
  ## Parâmetros
  
    - `service_name`: Nome do serviço protegido pelo circuit breaker
    - `config`: Novas configurações
  
  ## Retorno
  
    - `:ok` se a configuração for atualizada com sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec update_config(atom(), map()) :: :ok | {:error, term()}
  def update_config(service_name, config) do
    name = via_tuple(service_name)
    GenServer.call(name, {:update_config, config})
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init({service_name, config}) do
    Logger.info("Iniciando circuit breaker", %{
      module: __MODULE__,
      service_name: service_name
    })
    
    # Inicializa o estado com as configurações fornecidas
    state = %State{
      service_name: service_name,
      config: Map.merge(%State{}.config, config)
    }
    
    # Tenta carregar o estado do armazenamento
    state = case state.storage_adapter.load_state(service_name) do
      {:ok, {saved_state, metadata}} when saved_state in @states ->
        # Restaura o estado salvo
        %{state | 
          current_state: saved_state,
          opened_at: Map.get(metadata, :opened_at),
          failure_count: Map.get(metadata, :failure_count, 0),
          success_count: Map.get(metadata, :success_count, 0)
        }
        
      _ ->
        # Usa o estado padrão (fechado)
        state
    end
    
    # Registra métricas iniciais
    Metrics.gauge("deeper_hub.core.circuit_breaker.state", state_to_number(state.current_state), %{
      service_name: service_name
    })
    
    {:ok, state}
  end
  
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state.current_state}, state}
  end
  
  @impl true
  def handle_call(:reset, _from, state) do
    Logger.info("Resetando circuit breaker", %{
      module: __MODULE__,
      service_name: state.service_name,
      old_state: state.current_state
    })
    
    # Reseta para o estado fechado
    new_state = %{state | 
      current_state: :closed,
      failure_count: 0,
      success_count: 0,
      opened_at: nil
    }
    
    # Salva o novo estado
    :ok = save_state(new_state)
    
    # Registra a mudança de estado
    publish_state_change(state.current_state, :closed, :manual_reset, state.service_name)
    
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call({:update_config, new_config}, _from, state) do
    Logger.info("Atualizando configuração do circuit breaker", %{
      module: __MODULE__,
      service_name: state.service_name,
      old_config: state.config,
      new_config: new_config
    })
    
    # Atualiza a configuração
    updated_config = Map.merge(state.config, new_config)
    new_state = %{state | config: updated_config}
    
    {:reply, :ok, new_state}
  end
  
  @impl true
  def handle_call({:run, operation_fun, fallback_fun, opts}, _from, state) do
    # Verifica se o circuito permite a execução da operação
    {allow_request, state_after_check} = allow_request?(state)
    
    # Executa a operação ou fallback com base no estado do circuito
    {result, final_state} = 
      if allow_request do
        execute_operation(operation_fun, fallback_fun, state_after_check, opts)
      else
        # Circuito aberto, executa fallback ou retorna erro
        if fallback_fun do
          Logger.warning("Circuito aberto, executando fallback", %{
            module: __MODULE__,
            service_name: state.service_name
          })
          
          # Registra métrica de fallback usado
          Metrics.increment("deeper_hub.core.circuit_breaker.fallback.used", %{
            service_name: state.service_name
          })
          
          # Executa o fallback
          fallback_result = fallback_fun.(:circuit_open)
          {fallback_result, state_after_check}
        else
          Logger.warning("Circuito aberto, retornando erro", %{
            module: __MODULE__,
            service_name: state.service_name
          })
          
          {{:error, :circuit_open}, state_after_check}
        end
      end
    
    # Salva o estado final
    :ok = save_state(final_state)
    
    {:reply, result, final_state}
  end
  
  # Funções privadas
  
  # Verifica se uma requisição deve ser permitida com base no estado do circuito
  defp allow_request?(state) do
    case state.current_state do
      :closed ->
        # Circuito fechado, permite a requisição
        {true, state}
        
      :open ->
        # Circuito aberto, verifica se o timeout passou
        now = DateTime.utc_now()
        
        if state.opened_at && 
           DateTime.diff(now, state.opened_at, :millisecond) >= state.config.reset_timeout_ms do
          # Timeout passou, muda para meio-aberto
          Logger.info("Circuito passando para meio-aberto após timeout", %{
            module: __MODULE__,
            service_name: state.service_name,
            opened_at: state.opened_at,
            elapsed_ms: DateTime.diff(now, state.opened_at, :millisecond)
          })
          
          new_state = %{state | 
            current_state: :half_open,
            success_count: 0
          }
          
          # Registra a mudança de estado
          publish_state_change(:open, :half_open, :reset_timeout, state.service_name)
          
          # Permite a requisição no estado meio-aberto
          {true, new_state}
        else
          # Timeout não passou, mantém o circuito aberto
          {false, state}
        end
        
      :half_open ->
        # No estado meio-aberto, permite um número limitado de requisições
        {true, state}
    end
  end
  
  # Executa a operação protegida pelo circuit breaker
  defp execute_operation(operation_fun, fallback_fun, state, opts) do
    # Obtém o timeout da chamada
    call_timeout_ms = Keyword.get(opts, :call_timeout_ms, state.config.call_timeout_ms)
    
    # Registra o início da operação
    start_time = System.monotonic_time(:millisecond)
    
    # Executa a operação com timeout
    operation_result = 
      try do
        task = Task.async(fn -> operation_fun.() end)
        Task.yield(task, call_timeout_ms) || Task.shutdown(task)
      rescue
        e -> {:error, e}
      catch
        :exit, reason -> {:error, {:exit, reason}}
      end
    
    # Calcula a duração da operação
    duration_ms = System.monotonic_time(:millisecond) - start_time
    
    # Registra métrica de duração
    Metrics.histogram("deeper_hub.core.circuit_breaker.call.duration_ms", duration_ms, %{
      service_name: state.service_name
    })
    
    # Processa o resultado da operação
    case operation_result do
      {:ok, result} ->
        # Operação bem-sucedida
        Logger.debug("Operação protegida executada com sucesso", %{
          module: __MODULE__,
          service_name: state.service_name,
          duration_ms: duration_ms
        })
        
        # Registra métrica de sucesso
        Metrics.increment("deeper_hub.core.circuit_breaker.calls.total", %{
          service_name: state.service_name,
          status: "success"
        })
        
        # Atualiza o estado com base no resultado de sucesso
        new_state = handle_success(state)
        
        # Retorna o resultado e o novo estado
        {result, new_state}
        
      nil ->
        # Timeout
        Logger.warning("Timeout na operação protegida", %{
          module: __MODULE__,
          service_name: state.service_name,
          timeout_ms: call_timeout_ms,
          duration_ms: duration_ms
        })
        
        # Registra métrica de timeout
        Metrics.increment("deeper_hub.core.circuit_breaker.calls.total", %{
          service_name: state.service_name,
          status: "timeout"
        })
        
        # Atualiza o estado com base no resultado de falha (timeout)
        new_state = handle_failure(state)
        
        # Executa fallback ou retorna erro
        if fallback_fun do
          # Registra métrica de fallback usado
          Metrics.increment("deeper_hub.core.circuit_breaker.fallback.used", %{
            service_name: state.service_name
          })
          
          {fallback_fun.({:error, :timeout}), new_state}
        else
          {{:error, :timeout}, new_state}
        end
        
      {:error, reason} ->
        # Falha na operação
        Logger.warning("Falha na operação protegida", %{
          module: __MODULE__,
          service_name: state.service_name,
          reason: reason,
          duration_ms: duration_ms
        })
        
        # Registra métrica de falha
        Metrics.increment("deeper_hub.core.circuit_breaker.calls.total", %{
          service_name: state.service_name,
          status: "failure"
        })
        
        # Atualiza o estado com base no resultado de falha
        new_state = handle_failure(state)
        
        # Executa fallback ou retorna erro
        if fallback_fun do
          # Registra métrica de fallback usado
          Metrics.increment("deeper_hub.core.circuit_breaker.fallback.used", %{
            service_name: state.service_name
          })
          
          {fallback_fun.({:error, reason}), new_state}
        else
          {{:error, reason}, new_state}
        end
    end
  end
  
  # Atualiza o estado após uma operação bem-sucedida
  defp handle_success(state) do
    case state.current_state do
      :closed ->
        # No estado fechado, reseta o contador de falhas
        %{state | failure_count: 0}
        
      :half_open ->
        # No estado meio-aberto, incrementa o contador de sucessos
        new_success_count = state.success_count + 1
        
        if new_success_count >= state.config.success_threshold do
          # Atingiu o limiar de sucessos, fecha o circuito
          Logger.info("Circuito fechado após #{new_success_count} sucessos consecutivos", %{
            module: __MODULE__,
            service_name: state.service_name,
            success_threshold: state.config.success_threshold
          })
          
          # Registra a mudança de estado
          publish_state_change(:half_open, :closed, :success_threshold_reached, state.service_name)
          
          # Fecha o circuito
          %{state | 
            current_state: :closed,
            failure_count: 0,
            success_count: 0
          }
        else
          # Ainda não atingiu o limiar, mantém meio-aberto
          %{state | success_count: new_success_count}
        end
        
      _ ->
        # Não deveria chegar aqui, mas por segurança mantém o estado
        state
    end
  end
  
  # Atualiza o estado após uma operação com falha
  defp handle_failure(state) do
    case state.current_state do
      :closed ->
        # No estado fechado, incrementa o contador de falhas
        new_failure_count = state.failure_count + 1
        
        if new_failure_count >= state.config.failure_threshold do
          # Atingiu o limiar de falhas, abre o circuito
          Logger.warning("Circuito aberto após #{new_failure_count} falhas consecutivas", %{
            module: __MODULE__,
            service_name: state.service_name,
            failure_threshold: state.config.failure_threshold
          })
          
          # Registra a mudança de estado
          publish_state_change(:closed, :open, :failure_threshold_reached, state.service_name)
          
          # Abre o circuito
          %{state | 
            current_state: :open,
            failure_count: 0,
            opened_at: DateTime.utc_now()
          }
        else
          # Ainda não atingiu o limiar, mantém fechado
          %{state | failure_count: new_failure_count}
        end
        
      :half_open ->
        # No estado meio-aberto, qualquer falha abre o circuito novamente
        Logger.warning("Circuito reaberto após falha no estado meio-aberto", %{
          module: __MODULE__,
          service_name: state.service_name
        })
        
        # Registra a mudança de estado
        publish_state_change(:half_open, :open, :failure_in_half_open, state.service_name)
        
        # Abre o circuito
        %{state | 
          current_state: :open,
          failure_count: 0,
          success_count: 0,
          opened_at: DateTime.utc_now()
        }
        
      _ ->
        # Não deveria chegar aqui, mas por segurança mantém o estado
        state
    end
  end
  
  # Salva o estado atual no adaptador de armazenamento
  defp save_state(state) do
    # Atualiza a métrica de estado
    Metrics.gauge("deeper_hub.core.circuit_breaker.state", state_to_number(state.current_state), %{
      service_name: state.service_name
    })
    
    # Prepara os metadados para salvar
    metadata = %{
      failure_count: state.failure_count,
      success_count: state.success_count,
      opened_at: state.opened_at
    }
    
    # Salva no adaptador de armazenamento
    state.storage_adapter.save_state(state.service_name, state.current_state, metadata)
  end
  
  # Publica evento de mudança de estado
  defp publish_state_change(old_state, new_state, reason, service_name) do
    # Registra a mudança de estado nas métricas
    Metrics.gauge("deeper_hub.core.circuit_breaker.state", state_to_number(new_state), %{
      service_name: service_name
    })
    
    # Publica evento de telemetria
    :telemetry.execute(
      [:deeper_hub, :core, :circuit_breaker, :state_changed],
      %{timestamp: System.system_time(:millisecond)},
      %{
        service_name: service_name,
        old_state: old_state,
        new_state: new_state,
        reason: reason
      }
    )
  end
  
  # Converte estado para número (para métricas)
  defp state_to_number(:closed), do: 0
  defp state_to_number(:open), do: 1
  defp state_to_number(:half_open), do: 2
  
  # Cria um nome via Registry para o GenServer
  defp via_tuple(service_name) do
    {:via, Registry, {Deeper_Hub.Core.CircuitBreaker.InstanceRegistry, service_name}}
  end
end
