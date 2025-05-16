defmodule Deeper_Hub.Core.Telemetry.TelemetryBehaviour do
  @moduledoc """
  Comportamento que define a interface para operações de telemetria no sistema Deeper_Hub.

  Este módulo define o contrato que deve ser implementado por qualquer adaptador
  de telemetria no sistema, garantindo uma interface consistente para emissão
  de eventos e gerenciamento de handlers.

  ## Responsabilidades

  * Emitir eventos de telemetria em pontos estratégicos do sistema
  * Gerenciar o ciclo de vida dos handlers de telemetria
  * Fornecer suporte para medição de spans (operações com início e fim)
  * Integrar com sistemas de observabilidade
  """

  @doc """
  Executa um evento de telemetria.

  ## Parâmetros

    * `event_name` - Nome do evento, como uma lista de átomos (ex: [:deeper_hub, :cache, :put])
    * `measurements` - Mapa com medições numéricas associadas ao evento
    * `metadata` - Mapa com metadados contextuais do evento

  ## Retorno

    * `:ok` - O evento foi emitido com sucesso
  """
  @callback execute(event_name :: [atom()], measurements :: map(), metadata :: map()) :: :ok

  @doc """
  Anexa um handler a um evento específico de telemetria.

  ## Parâmetros

    * `handler_id` - Identificador único para o handler
    * `event_name` - Nome do evento ao qual o handler será anexado
    * `handler_function` - Função a ser chamada quando o evento ocorrer
    * `config` - Configuração opcional para o handler

  ## Retorno

    * `:ok` - O handler foi anexado com sucesso
    * `{:error, reason}` - Falha ao anexar o handler
  """
  @callback attach(
              handler_id :: term(),
              event_name :: [atom()],
              handler_function :: function(),
              config :: term()
            ) :: :ok | {:error, term()}

  @doc """
  Anexa um handler a múltiplos eventos de telemetria.

  ## Parâmetros

    * `handler_id` - Identificador único para o handler
    * `event_names` - Lista de nomes de eventos aos quais o handler será anexado
    * `handler_function` - Função a ser chamada quando qualquer dos eventos ocorrer
    * `config` - Configuração opcional para o handler

  ## Retorno

    * `:ok` - O handler foi anexado com sucesso a todos os eventos
    * `{:error, reason}` - Falha ao anexar o handler
  """
  @callback attach_many(
              handler_id :: term(),
              event_names :: [[atom()]],
              handler_function :: function(),
              config :: term()
            ) :: :ok | {:error, term()}

  @doc """
  Remove um handler previamente anexado.

  ## Parâmetros

    * `handler_id` - Identificador do handler a ser removido

  ## Retorno

    * `:ok` - O handler foi removido com sucesso
    * `{:error, :not_found}` - O handler não foi encontrado
  """
  @callback detach(handler_id :: term()) :: :ok | {:error, :not_found}

  @doc """
  Lista todos os handlers atualmente anexados.

  ## Retorno

    * `[{handler_id, event_name, handler_function, config}]` - Lista de handlers
  """
  @callback list_handlers() :: [{term(), [atom()], function(), term()}]

  @doc """
  Executa uma operação medindo seu tempo de execução e emitindo eventos de início e fim.

  ## Parâmetros

    * `event_prefix` - Prefixo do nome do evento (ex: [:deeper_hub, :cache])
    * `start_metadata` - Metadados a serem incluídos no evento de início
    * `function` - Função a ser executada e medida

  ## Retorno

    * O valor retornado pela função executada

  ## Eventos Emitidos

    * `event_prefix ++ [:start]` - No início da execução
    * `event_prefix ++ [:stop]` - No fim da execução bem-sucedida
    * `event_prefix ++ [:exception]` - Em caso de exceção
  """
  @callback span(
              event_prefix :: [atom()],
              start_metadata :: map(),
              function :: (-> {term(), map()} | term())
            ) :: term()
end
