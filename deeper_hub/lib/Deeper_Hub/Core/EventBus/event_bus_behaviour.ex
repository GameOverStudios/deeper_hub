defmodule Deeper_Hub.Core.EventBus.EventBusBehaviour do
  @moduledoc """
  Comportamento que define a interface para operações de barramento de eventos no sistema DeeperHub.
  
  Este módulo define o contrato que deve ser implementado por qualquer adaptador
  de barramento de eventos no sistema, garantindo uma interface consistente para
  publicação e consumo de eventos.
  
  ## Responsabilidades
  
  * Publicar eventos para tópicos específicos
  * Registrar consumidores para tópicos de interesse
  * Gerenciar o ciclo de vida dos eventos
  * Garantir a entrega confiável de eventos para os consumidores
  """
  
  @doc """
  Registra um tópico no barramento de eventos.
  
  ## Parâmetros
  
    * `topic` - Nome do tópico a ser registrado
    
  ## Retorno
  
    * `:ok` - Tópico registrado com sucesso
    * `{:error, reason}` - Falha ao registrar o tópico
  """
  @callback register_topic(topic :: atom()) :: :ok | {:error, term()}
  
  @doc """
  Registra um consumidor para um tópico específico.
  
  ## Parâmetros
  
    * `subscriber_name` - Nome único do consumidor
    * `topics` - Lista de tópicos de interesse
    * `handler_function` - Função a ser chamada quando um evento for publicado
    
  ## Retorno
  
    * `:ok` - Consumidor registrado com sucesso
    * `{:error, reason}` - Falha ao registrar o consumidor
  """
  @callback subscribe(
              subscriber_name :: term(),
              topics :: [atom()],
              handler_function :: function()
            ) :: :ok | {:error, term()}
  
  @doc """
  Remove um consumidor previamente registrado.
  
  ## Parâmetros
  
    * `subscriber_name` - Nome do consumidor a ser removido
    
  ## Retorno
  
    * `:ok` - Consumidor removido com sucesso
    * `{:error, :not_found}` - Consumidor não encontrado
  """
  @callback unsubscribe(subscriber_name :: term()) :: :ok | {:error, :not_found}
  
  @doc """
  Publica um evento em um tópico específico.
  
  ## Parâmetros
  
    * `topic` - Tópico do evento
    * `data` - Dados do evento
    * `metadata` - Metadados adicionais do evento (opcional)
    
  ## Retorno
  
    * `:ok` - Evento publicado com sucesso
    * `{:error, reason}` - Falha ao publicar o evento
  """
  @callback publish(topic :: atom(), data :: term(), metadata :: map()) :: :ok | {:error, term()}
  
  @doc """
  Lista todos os tópicos registrados.
  
  ## Retorno
  
    * `[topic]` - Lista de tópicos registrados
  """
  @callback list_topics() :: [atom()]
  
  @doc """
  Lista todos os consumidores registrados.
  
  ## Retorno
  
    * `[{subscriber_name, topics}]` - Lista de consumidores e seus tópicos
  """
  @callback list_subscribers() :: [{term(), [atom()]}]
  
  @doc """
  Marca um evento como processado por um consumidor específico.
  
  ## Parâmetros
  
    * `event_id` - Identificador do evento
    * `subscriber_name` - Nome do consumidor que processou o evento
    
  ## Retorno
  
    * `:ok` - Evento marcado como processado com sucesso
    * `{:error, reason}` - Falha ao marcar o evento como processado
  """
  @callback mark_as_completed(event_id :: term(), subscriber_name :: term()) :: :ok | {:error, term()}
  
  @doc """
  Marca um evento como falho por um consumidor específico.
  
  ## Parâmetros
  
    * `event_id` - Identificador do evento
    * `subscriber_name` - Nome do consumidor que falhou ao processar o evento
    * `error_reason` - Motivo da falha
    
  ## Retorno
  
    * `:ok` - Evento marcado como falho com sucesso
    * `{:error, reason}` - Falha ao marcar o evento como falho
  """
  @callback mark_as_failed(event_id :: term(), subscriber_name :: term(), error_reason :: term()) ::
              :ok | {:error, term()}
  
  @doc """
  Obtém o status de um evento.
  
  ## Parâmetros
  
    * `event_id` - Identificador do evento
    
  ## Retorno
  
    * `{:ok, status}` - Status do evento obtido com sucesso
    * `{:error, :not_found}` - Evento não encontrado
  """
  @callback get_event_status(event_id :: term()) :: {:ok, term()} | {:error, :not_found}
end
