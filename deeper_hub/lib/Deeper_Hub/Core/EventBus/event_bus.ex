defmodule Deeper_Hub.Core.EventBus do
  @moduledoc """
  Módulo principal para gerenciamento do EventBus.
  
  Este módulo é responsável por configurar e gerenciar o EventBus,
  fornecendo funções auxiliares para publicar eventos e gerenciar tópicos.
  """
  
  alias Deeper_Hub.Core.Logger
  alias EventBus.Model.Event
  
  @doc """
  Inicializa o EventBus com os tópicos padrão.
  
  Esta função deve ser chamada durante a inicialização da aplicação.
  """
  def init do
    Logger.info("Inicializando EventBus", %{module: __MODULE__})
    
    # Registra os tópicos padrão
    register_default_topics()
    
    # Registra os subscribers padrão
    register_default_subscribers()
    
    :ok
  end
  
  @doc """
  Registra os tópicos padrão no EventBus.
  
  ## Tópicos padrão:
  
    - `:user_created` - Quando um usuário é criado
    - `:user_updated` - Quando um usuário é atualizado
    - `:user_deleted` - Quando um usuário é excluído
    - `:user_authenticated` - Quando um usuário é autenticado
    - `:cache_hit` - Quando ocorre um hit no cache
    - `:cache_miss` - Quando ocorre um miss no cache
    - `:query_executed` - Quando uma consulta SQL é executada
    - `:transaction_completed` - Quando uma transação é concluída
    - `:error_occurred` - Quando ocorre um erro na aplicação
  """
  def register_default_topics do
    topics = [
      :user_created,
      :user_updated,
      :user_deleted,
      :user_authenticated,
      :cache_hit,
      :cache_miss,
      :query_executed,
      :transaction_completed,
      :error_occurred
    ]
    
    Enum.each(topics, fn topic ->
      case EventBus.topic_exist?(topic) do
        false ->
          Logger.debug("Registrando tópico EventBus", %{module: __MODULE__, topic: topic})
          EventBus.register_topic(topic)
        true ->
          Logger.debug("Tópico EventBus já registrado", %{module: __MODULE__, topic: topic})
      end
    end)
  end
  
  @doc """
  Registra os subscribers padrão no EventBus.
  """
  def register_default_subscribers do
    # Aqui serão registrados os subscribers padrão quando forem implementados
    :ok
  end
  
  @doc """
  Publica um evento no EventBus.
  
  ## Parâmetros
  
    - `topic`: O tópico do evento
    - `data`: Os dados do evento
    - `opts`: Opções adicionais (opcional)
  
  ## Opções
  
    - `:source` - A fonte do evento (padrão: "deeper_hub")
    - `:transaction_id` - O ID da transação (opcional)
    - `:ttl` - Tempo de vida do evento em milissegundos (opcional)
  
  ## Retorno
  
    - `:ok` - Se o evento for publicado com sucesso
  
  ## Exemplo
  
  ```elixir
  Deeper_Hub.Core.EventBus.publish(:user_created, %{id: 123, username: "johndoe"})
  ```
  """
  def publish(topic, data, opts \\ []) do
    # Verifica se o tópico existe
    unless EventBus.topic_exist?(topic) do
      Logger.warning("Tentativa de publicar em tópico não registrado", %{
        module: __MODULE__,
        topic: topic
      })
      
      # Registra o tópico automaticamente
      EventBus.register_topic(topic)
    end
    
    # Obtém as opções
    source = Keyword.get(opts, :source, "deeper_hub")
    transaction_id = Keyword.get(opts, :transaction_id)
    ttl = Keyword.get(opts, :ttl)
    
    # Cria o evento
    event_id = "#{topic}_#{:os.system_time(:millisecond)}"
    initialized_at = :os.system_time(:millisecond)
    
    # Constrói o evento usando o EventBus.Model.Event
    event = %Event{
      id: event_id,
      topic: topic,
      data: data,
      source: source,
      initialized_at: initialized_at,
      occurred_at: :os.system_time(:millisecond)
    }
    
    # Adiciona o transaction_id se fornecido
    event = if transaction_id, do: Map.put(event, :transaction_id, transaction_id), else: event
    
    # Adiciona o ttl se fornecido
    event = if ttl, do: Map.put(event, :ttl, ttl), else: event
    
    # Publica o evento
    EventBus.notify(event)
    
    Logger.debug("Evento publicado", %{
      module: __MODULE__,
      topic: topic,
      event_id: event_id
    })
    
    :ok
  end
  
  @doc """
  Registra um novo tópico no EventBus.
  
  ## Parâmetros
  
    - `topic`: O tópico a ser registrado
  
  ## Retorno
  
    - `:ok` - Se o tópico for registrado com sucesso
    - `{:error, :already_exists}` - Se o tópico já existir
  """
  def register_topic(topic) do
    case EventBus.topic_exist?(topic) do
      false ->
        Logger.debug("Registrando tópico EventBus", %{module: __MODULE__, topic: topic})
        EventBus.register_topic(topic)
        :ok
      true ->
        Logger.debug("Tópico EventBus já registrado", %{module: __MODULE__, topic: topic})
        {:error, :already_exists}
    end
  end
  
  @doc """
  Desregistra um tópico do EventBus.
  
  ## Parâmetros
  
    - `topic`: O tópico a ser desregistrado
  
  ## Retorno
  
    - `:ok` - Se o tópico for desregistrado com sucesso
    - `{:error, :not_found}` - Se o tópico não existir
  """
  def unregister_topic(topic) do
    case EventBus.topic_exist?(topic) do
      true ->
        Logger.debug("Desregistrando tópico EventBus", %{module: __MODULE__, topic: topic})
        EventBus.unregister_topic(topic)
        :ok
      false ->
        Logger.debug("Tópico EventBus não encontrado", %{module: __MODULE__, topic: topic})
        {:error, :not_found}
    end
  end
  
  @doc """
  Registra um subscriber no EventBus.
  
  ## Parâmetros
  
    - `subscriber`: O módulo subscriber ou {módulo, config}
    - `topics`: Lista de padrões de tópicos para assinar (regex)
  
  ## Retorno
  
    - `:ok` - Se o subscriber for registrado com sucesso
  
  ## Exemplo
  
  ```elixir
  Deeper_Hub.Core.EventBus.subscribe(MySubscriber, ["user_.*"])
  ```
  """
  def subscribe(subscriber, topics) do
    Logger.debug("Registrando subscriber EventBus", %{
      module: __MODULE__,
      subscriber: inspect(subscriber),
      topics: topics
    })
    
    EventBus.subscribe({subscriber, topics})
    :ok
  end
  
  @doc """
  Desregistra um subscriber do EventBus.
  
  ## Parâmetros
  
    - `subscriber`: O módulo subscriber ou {módulo, config}
  
  ## Retorno
  
    - `:ok` - Se o subscriber for desregistrado com sucesso
  """
  def unsubscribe(subscriber) do
    Logger.debug("Desregistrando subscriber EventBus", %{
      module: __MODULE__,
      subscriber: inspect(subscriber)
    })
    
    EventBus.unsubscribe(subscriber)
    :ok
  end
  
  @doc """
  Lista todos os subscribers registrados no EventBus.
  
  ## Retorno
  
    - Lista de subscribers
  """
  def subscribers do
    EventBus.subscribers()
  end
  
  @doc """
  Lista todos os subscribers de um tópico específico.
  
  ## Parâmetros
  
    - `topic`: O tópico
  
  ## Retorno
  
    - Lista de subscribers do tópico
  """
  def subscribers(topic) do
    EventBus.subscribers(topic)
  end
  
  @doc """
  Verifica se um tópico existe no EventBus.
  
  ## Parâmetros
  
    - `topic`: O tópico a ser verificado
  
  ## Retorno
  
    - `true` - Se o tópico existir
    - `false` - Se o tópico não existir
  """
  def topic_exist?(topic) do
    EventBus.topic_exist?(topic)
  end
end
