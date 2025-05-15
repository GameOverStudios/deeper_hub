defmodule Deeper_Hub.Core.EventBus.EventBusAdapter do
  @moduledoc """
  Adaptador para a biblioteca EventBus que implementa o comportamento EventBusBehaviour.
  
  Este módulo fornece uma implementação completa das operações de barramento de eventos
  usando a biblioteca `:event_bus`, permitindo a publicação e consumo de eventos
  para comunicação entre componentes do sistema.
  
  ## Funcionalidades
  
  * 📢 Publicação de eventos para tópicos específicos
  * 👂 Registro de consumidores para tópicos de interesse
  * 🔄 Gerenciamento do ciclo de vida dos eventos
  * ✅ Confirmação de processamento de eventos
  
  ## Exemplos
  
  ```elixir
  # Registrar um tópico
  EventBusAdapter.register_topic(:user_registered)
  
  # Publicar um evento
  EventBusAdapter.publish(:user_registered, %{id: 123, email: "user@example.com"})
  
  # Registrar um consumidor
  EventBusAdapter.subscribe(
    :email_sender,
    [:user_registered],
    &EmailSender.handle_event/1
  )
  ```
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.EventBus.EventBusBehaviour
  
  @behaviour EventBusBehaviour
  
  @doc """
  Registra um tópico no barramento de eventos.
  
  ## Parâmetros
  
    * `topic` - Nome do tópico a ser registrado
    
  ## Retorno
  
    * `:ok` - Tópico registrado com sucesso
    * `{:error, reason}` - Falha ao registrar o tópico
    
  ## Exemplos
  
  ```elixir
  EventBusAdapter.register_topic(:user_registered)
  ```
  """
  @impl EventBusBehaviour
  @spec register_topic(atom()) :: :ok | {:error, term()}
  def register_topic(topic) when is_atom(topic) do
    # Log de início da operação
    Logger.debug("Registrando tópico no barramento de eventos", %{
      module: __MODULE__,
      topic: topic
    })
    
    try do
      # Registra o tópico usando a biblioteca :event_bus
      :ok = EventBus.register_topic(topic)
      
      Logger.debug("Tópico registrado com sucesso", %{
        module: __MODULE__,
        topic: topic
      })
      
      :ok
    rescue
      e ->
        Logger.error("Falha ao registrar tópico no barramento de eventos", %{
          module: __MODULE__,
          topic: topic,
          error: inspect(e)
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Registra um consumidor para um tópico específico.
  
  ## Parâmetros
  
    * `subscriber_name` - Nome único do consumidor
    * `topics` - Lista de tópicos de interesse
    * `handler_function` - Função a ser chamada quando um evento for publicado
    
  ## Retorno
  
    * `:ok` - Consumidor registrado com sucesso
    * `{:error, reason}` - Falha ao registrar o consumidor
    
  ## Exemplos
  
  ```elixir
  EventBusAdapter.subscribe(
    :email_sender,
    [:user_registered, :password_reset_requested],
    &EmailSender.handle_event/1
  )
  ```
  """
  @impl EventBusBehaviour
  @spec subscribe(term(), [atom()], function()) :: :ok | {:error, term()}
  def subscribe(subscriber_name, topics, handler_function) when is_list(topics) and is_function(handler_function) do
    # Log de início da operação
    Logger.debug("Registrando consumidor no barramento de eventos", %{
      module: __MODULE__,
      subscriber: subscriber_name,
      topics: topics
    })
    
    try do
      # Registra o consumidor usando a biblioteca :event_bus
      :ok = EventBus.subscribe({subscriber_name, topics})
      
      # Armazena a função de handler para uso posterior
      # A biblioteca EventBus não gerencia isso diretamente, então precisamos fazer isso
      Process.put({:event_handler, subscriber_name}, handler_function)
      
      Logger.debug("Consumidor registrado com sucesso", %{
        module: __MODULE__,
        subscriber: subscriber_name,
        topics: topics
      })
      
      :ok
    rescue
      e ->
        Logger.error("Falha ao registrar consumidor no barramento de eventos", %{
          module: __MODULE__,
          subscriber: subscriber_name,
          topics: topics,
          error: inspect(e)
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Remove um consumidor previamente registrado.
  
  ## Parâmetros
  
    * `subscriber_name` - Nome do consumidor a ser removido
    
  ## Retorno
  
    * `:ok` - Consumidor removido com sucesso
    * `{:error, :not_found}` - Consumidor não encontrado
    
  ## Exemplos
  
  ```elixir
  EventBusAdapter.unsubscribe(:email_sender)
  ```
  """
  @impl EventBusBehaviour
  @spec unsubscribe(term()) :: :ok | {:error, :not_found}
  def unsubscribe(subscriber_name) do
    # Log de início da operação
    Logger.debug("Removendo consumidor do barramento de eventos", %{
      module: __MODULE__,
      subscriber: subscriber_name
    })
    
    try do
      # Remove o consumidor usando a biblioteca :event_bus
      :ok = EventBus.unsubscribe({subscriber_name})
      
      # Remove a função de handler armazenada
      Process.delete({:event_handler, subscriber_name})
      
      Logger.debug("Consumidor removido com sucesso", %{
        module: __MODULE__,
        subscriber: subscriber_name
      })
      
      :ok
    rescue
      e ->
        Logger.error("Falha ao remover consumidor do barramento de eventos", %{
          module: __MODULE__,
          subscriber: subscriber_name,
          error: inspect(e)
        })
        
        {:error, :not_found}
    end
  end
  
  @doc """
  Publica um evento em um tópico específico.
  
  ## Parâmetros
  
    * `topic` - Tópico do evento
    * `data` - Dados do evento
    * `metadata` - Metadados adicionais do evento (opcional)
    
  ## Retorno
  
    * `:ok` - Evento publicado com sucesso
    * `{:error, reason}` - Falha ao publicar o evento
    
  ## Exemplos
  
  ```elixir
  EventBusAdapter.publish(
    :user_registered,
    %{id: 123, email: "user@example.com"},
    %{source: "registration_service"}
  )
  ```
  """
  @impl EventBusBehaviour
  @spec publish(atom(), term(), map()) :: :ok | {:error, term()}
  def publish(topic, data, metadata \\ %{}) when is_atom(topic) and is_map(metadata) do
    # Log de início da operação
    Logger.debug("Publicando evento no barramento de eventos", %{
      module: __MODULE__,
      topic: topic,
      metadata: sanitize_metadata(metadata)
    })
    
    try do
      # Cria o evento usando a estrutura esperada pela biblioteca :event_bus
      # Extrair campos especiais dos metadados para usar nos campos nativos do EventBus
      # e manter o restante no campo data
      transaction_id = Map.get(metadata, :transaction_id)
      source = Map.get(metadata, :source, __MODULE__)
      ttl = Map.get(metadata, :ttl)
      
      # Remover campos especiais dos metadados para evitar duplicação
      filtered_metadata = metadata
        |> Map.drop([:transaction_id, :source, :ttl])
      
      # Combinar dados e metadados restantes
      event_data = %{
        payload: data,
        metadata: filtered_metadata
      }
      
      # Obter timestamps atuais
      now = System.system_time(:microsecond)
      
      # Criar o evento com todos os campos suportados pela biblioteca
      event = %EventBus.Model.Event{
        id: UUID.uuid4(),
        transaction_id: transaction_id,
        topic: topic,
        data: event_data,
        initialized_at: now,
        occurred_at: now,
        source: source,
        ttl: ttl
      }
      
      # Publica o evento usando a biblioteca :event_bus
      :ok = EventBus.notify(event)
      
      Logger.debug("Evento publicado com sucesso", %{
        module: __MODULE__,
        topic: topic,
        event_id: event.id
      })
      
      :ok
    rescue
      e ->
        Logger.error("Falha ao publicar evento no barramento de eventos", %{
          module: __MODULE__,
          topic: topic,
          error: inspect(e)
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Lista todos os tópicos registrados.
  
  ## Retorno
  
    * `[topic]` - Lista de tópicos registrados
    
  ## Exemplos
  
  ```elixir
  topics = EventBusAdapter.list_topics()
  ```
  """
  @impl EventBusBehaviour
  @spec list_topics() :: [atom()]
  def list_topics do
    # Log de início da operação
    Logger.debug("Listando tópicos do barramento de eventos", %{
      module: __MODULE__
    })
    
    # Lista os tópicos usando a biblioteca :event_bus
    topics = EventBus.topics()
    
    Logger.debug("Tópicos listados com sucesso", %{
      module: __MODULE__,
      topics: topics
    })
    
    topics
  end
  
  @doc """
  Lista todos os consumidores registrados.
  
  ## Retorno
  
    * `[{subscriber_name, topics}]` - Lista de consumidores e seus tópicos
    
  ## Exemplos
  
  ```elixir
  subscribers = EventBusAdapter.list_subscribers()
  ```
  """
  @impl EventBusBehaviour
  @spec list_subscribers() :: [{term(), [atom()]}]
  def list_subscribers do
    # Log de início da operação
    Logger.debug("Listando consumidores do barramento de eventos", %{
      module: __MODULE__
    })
    
    # Lista os consumidores usando a biblioteca :event_bus
    subscribers = EventBus.subscribers()
    
    # Formata a saída para o formato esperado
    formatted_subscribers =
      subscribers
      |> Enum.map(fn {subscriber, topics} -> {subscriber, topics} end)
    
    Logger.debug("Consumidores listados com sucesso", %{
      module: __MODULE__,
      subscribers: formatted_subscribers
    })
    
    formatted_subscribers
  end
  
  @doc """
  Marca um evento como processado por um consumidor específico.
  
  ## Parâmetros
  
    * `event_id` - Identificador do evento
    * `subscriber_name` - Nome do consumidor que processou o evento
    
  ## Retorno
  
    * `:ok` - Evento marcado como processado com sucesso
    * `{:error, reason}` - Falha ao marcar o evento como processado
    
  ## Exemplos
  
  ```elixir
  EventBusAdapter.mark_as_completed("event-123", :email_sender)
  ```
  """
  @impl EventBusBehaviour
  @spec mark_as_completed(term(), term()) :: :ok | {:error, term()}
  def mark_as_completed(event_id, subscriber_name) do
    # Log de início da operação
    Logger.debug("Marcando evento como processado", %{
      module: __MODULE__,
      event_id: event_id,
      subscriber: subscriber_name
    })
    
    try do
      # Marca o evento como processado usando a biblioteca :event_bus
      :ok = EventBus.mark_as_completed({subscriber_name, event_id})
      
      Logger.debug("Evento marcado como processado com sucesso", %{
        module: __MODULE__,
        event_id: event_id,
        subscriber: subscriber_name
      })
      
      :ok
    rescue
      e ->
        Logger.error("Falha ao marcar evento como processado", %{
          module: __MODULE__,
          event_id: event_id,
          subscriber: subscriber_name,
          error: inspect(e)
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Marca um evento como falho por um consumidor específico.
  
  ## Parâmetros
  
    * `event_id` - Identificador do evento
    * `subscriber_name` - Nome do consumidor que falhou ao processar o evento
    * `error_reason` - Motivo da falha
    
  ## Retorno
  
    * `:ok` - Evento marcado como falho com sucesso
    * `{:error, reason}` - Falha ao marcar o evento como falho
    
  ## Exemplos
  
  ```elixir
  EventBusAdapter.mark_as_failed("event-123", :email_sender, "SMTP connection error")
  ```
  """
  @impl EventBusBehaviour
  @spec mark_as_failed(term(), term(), term()) :: :ok | {:error, term()}
  def mark_as_failed(event_id, subscriber_name, error_reason) do
    # Log de início da operação
    Logger.debug("Marcando evento como falho", %{
      module: __MODULE__,
      event_id: event_id,
      subscriber: subscriber_name,
      error_reason: error_reason
    })
    
    try do
      # Marca o evento como falho usando a biblioteca :event_bus
      # A biblioteca não tem suporte direto para marcar como falho com uma razão,
      # então vamos usar o mesmo método de completado, mas registrar o erro no log
      :ok = EventBus.mark_as_completed({subscriber_name, event_id})
      
      # Registra a falha no log
      Logger.error("Falha no processamento de evento", %{
        module: __MODULE__,
        event_id: event_id,
        subscriber: subscriber_name,
        error_reason: error_reason
      })
      
      Logger.debug("Evento marcado como falho com sucesso", %{
        module: __MODULE__,
        event_id: event_id,
        subscriber: subscriber_name
      })
      
      :ok
    rescue
      e ->
        Logger.error("Falha ao marcar evento como falho", %{
          module: __MODULE__,
          event_id: event_id,
          subscriber: subscriber_name,
          error: inspect(e)
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Obtém o status de um evento.
  
  ## Parâmetros
  
    * `event_id` - Identificador do evento
    
  ## Retorno
  
    * `{:ok, status}` - Status do evento obtido com sucesso
    * `{:error, :not_found}` - Evento não encontrado
    
  ## Exemplos
  
  ```elixir
  {:ok, status} = EventBusAdapter.get_event_status("event-123")
  ```
  """
  @impl EventBusBehaviour
  @spec get_event_status(term()) :: {:ok, term()} | {:error, :not_found}
  def get_event_status(event_id) do
    # Log de início da operação
    Logger.debug("Obtendo status do evento", %{
      module: __MODULE__,
      event_id: event_id
    })
    
    # A biblioteca :event_bus não fornece uma API para obter o status de um evento específico
    # Vamos implementar uma versão simplificada que verifica se o evento existe
    case EventBus.fetch_event(event_id) do
      {:ok, event} ->
        # Obtém a lista de consumidores registrados para o tópico do evento
        # Já que não há uma função para obter consumidores que processaram um evento específico
        topic_subscribers = EventBus.subscribers(event.topic)
        
        status = %{
          id: event.id,
          topic: event.topic,
          occurred_at: event.occurred_at,
          subscribers: topic_subscribers
        }
        
        Logger.debug("Status do evento obtido com sucesso", %{
          module: __MODULE__,
          event_id: event_id,
          status: status
        })
        
        {:ok, status}
        
      :not_found ->
        Logger.debug("Evento não encontrado", %{
          module: __MODULE__,
          event_id: event_id
        })
        
        {:error, :not_found}
    end
  end
  
  # Funções privadas para sanitização de dados
  
  # Sanitiza metadados para evitar exposição de dados sensíveis nos logs
  @spec sanitize_metadata(map()) :: map()
  defp sanitize_metadata(metadata) do
    # Filtra campos potencialmente sensíveis dos metadados
    sensitive_keys = [:password, :token, :api_key, :secret, :credentials]
    
    metadata
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      if key in sensitive_keys do
        Map.put(acc, key, "[REDACTED]")
      else
        Map.put(acc, key, value)
      end
    end)
  end
end
