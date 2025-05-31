defmodule DeeperHub.Core.EventManager.Subscriber do
  @moduledoc """
  Módulo base para implementação de subscribers de eventos no DeeperHub.
  
  Este módulo define a interface e comportamentos padrão para os subscribers
  de eventos, facilitando a criação de novos consumidores de eventos no sistema.
  """

  @doc """
  Callback que define o comportamento principal de um subscriber.
  
  Cada subscriber deve implementar esta função para processar
  eventos dos tópicos aos quais está inscrito.
  
  ## Parâmetros
  
    * `event_shadow` - Shadow do evento no formato `{topic, id}`
  
  ## Retorno
  
  Retorna `:ok` em caso de sucesso.
  """
  @callback process(event_shadow :: {atom(), String.t()}) :: :ok

  @doc """
  Inicializa um módulo subscriber inscrevendo-o nos tópicos especificados.
  
  ## Parâmetros
  
    * `module` - Módulo do subscriber
    * `topics` - Lista de tópicos (strings ou regex patterns) para subscrição
  
  ## Exemplos
  
      defmodule MySubscriber do
        use DeeperHub.Core.EventManager.Subscriber, topics: ["user_.*"]
        
        # Implementação...
      end
  
  """
  defmacro __using__(opts) do
    topics = Keyword.get(opts, :topics, [".*"])
    
    quote do
      @behaviour DeeperHub.Core.EventManager.Subscriber
      
      @doc false
      def __subscriber_topics__, do: unquote(topics)
      
      @doc """
      Inicia o subscriber registrando-o no EventManager.
      """
      def start do
        DeeperHub.Core.EventManager.subscribe(__MODULE__, __subscriber_topics__())
      end
      
      @doc """
      Para o subscriber cancelando sua inscrição no EventManager.
      """
      def stop do
        DeeperHub.Core.EventManager.unsubscribe(__MODULE__)
      end
      
      @doc """
      Marca um evento como processado.
      """
      def mark_as_completed(event_shadow) do
        DeeperHub.Core.EventManager.mark_as_completed(__MODULE__, event_shadow)
      end
      
      @doc """
      Marca um evento como ignorado.
      """
      def mark_as_skipped(event_shadow) do
        DeeperHub.Core.EventManager.mark_as_skipped(__MODULE__, event_shadow)
      end
      
      @doc """
      Obtém o evento completo a partir do shadow.
      """
      def fetch_event(event_shadow) do
        DeeperHub.Core.EventManager.fetch_event(event_shadow)
      end
      
      # Permita que o módulo que usa este comportamento sobrescreva
      defoverridable [start: 0, stop: 0]
    end
  end
end
