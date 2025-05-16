defmodule Deeper_Hub.Core.Telemetry.Events do
  @moduledoc """
  Define os eventos de telemetria padrão para o sistema DeeperHub.
  
  Este módulo centraliza a definição de todos os eventos de telemetria
  utilizados no sistema, garantindo consistência e evitando duplicação
  de nomes de eventos em diferentes partes da aplicação.
  
  ## Estrutura de Eventos
  
  Os eventos seguem uma estrutura hierárquica com os seguintes níveis:
  
  * `:deeper_hub` - Prefixo para todos os eventos do sistema
  * `:subsystem` - Subsistema que emite o evento (ex: `:cache`, `:repository`)
  * `:operation` - Operação específica sendo realizada (ex: `:get`, `:put`)
  * `:action` - Ação específica (ex: `:start`, `:stop`, `:exception`)
  
  ## Exemplo de Uso
  
  ```elixir
  alias Deeper_Hub.Core.Telemetry.Events
  alias Deeper_Hub.Core.Telemetry.TelemetryFacade
  
  # Emitir um evento de cache hit
  TelemetryFacade.execute(Events.cache_hit(), %{count: 1}, %{key: "user_123"})
  
  # Medir o tempo de uma operação de repositório
  TelemetryFacade.span(
    Events.repository_query(),
    %{query: "SELECT * FROM users"},
    fn ->
      result = perform_query()
      {result, %{rows: length(result)}}
    end
  )
  ```
  """
  
  # Prefixo base para todos os eventos do sistema
  @base_prefix [:deeper_hub]
  
  # Eventos relacionados ao sistema de cache
  @cache_prefix @base_prefix ++ [:cache]
  
  @doc """
  Retorna o prefixo base para eventos de cache.
  
  ## Retorno
  
    * `[:deeper_hub, :cache]` - Prefixo para eventos de cache
  """
  @spec cache() :: [atom()]
  def cache, do: @cache_prefix
  
  @doc """
  Retorna o evento para operação de get no cache.
  
  ## Retorno
  
    * `[:deeper_hub, :cache, :get]` - Evento para operação de get
  """
  @spec cache_get() :: [atom()]
  def cache_get, do: @cache_prefix ++ [:get]
  
  @doc """
  Retorna o evento para operação de put no cache.
  
  ## Retorno
  
    * `[:deeper_hub, :cache, :put]` - Evento para operação de put
  """
  @spec cache_put() :: [atom()]
  def cache_put, do: @cache_prefix ++ [:put]
  
  @doc """
  Retorna o evento para cache hit (chave encontrada).
  
  ## Retorno
  
    * `[:deeper_hub, :cache, :hit]` - Evento para cache hit
  """
  @spec cache_hit() :: [atom()]
  def cache_hit, do: @cache_prefix ++ [:hit]
  
  @doc """
  Retorna o evento para cache miss (chave não encontrada).
  
  ## Retorno
  
    * `[:deeper_hub, :cache, :miss]` - Evento para cache miss
  """
  @spec cache_miss() :: [atom()]
  def cache_miss, do: @cache_prefix ++ [:miss]
  
  @doc """
  Retorna o evento para operação de delete no cache.
  
  ## Retorno
  
    * `[:deeper_hub, :cache, :delete]` - Evento para operação de delete
  """
  @spec cache_delete() :: [atom()]
  def cache_delete, do: @cache_prefix ++ [:delete]
  
  @doc """
  Retorna o evento para operação de clear no cache.
  
  ## Retorno
  
    * `[:deeper_hub, :cache, :clear]` - Evento para operação de clear
  """
  @spec cache_clear() :: [atom()]
  def cache_clear, do: @cache_prefix ++ [:clear]
  
  # Eventos relacionados ao sistema de repositório
  @repository_prefix @base_prefix ++ [:repository]
  
  @doc """
  Retorna o prefixo base para eventos de repositório.
  
  ## Retorno
  
    * `[:deeper_hub, :repository]` - Prefixo para eventos de repositório
  """
  @spec repository() :: [atom()]
  def repository, do: @repository_prefix
  
  @doc """
  Retorna o evento para operação de query no repositório.
  
  ## Retorno
  
    * `[:deeper_hub, :repository, :query]` - Evento para operação de query
  """
  @spec repository_query() :: [atom()]
  def repository_query, do: @repository_prefix ++ [:query]
  
  @doc """
  Retorna o evento para operação de insert no repositório.
  
  ## Retorno
  
    * `[:deeper_hub, :repository, :insert]` - Evento para operação de insert
  """
  @spec repository_insert() :: [atom()]
  def repository_insert, do: @repository_prefix ++ [:insert]
  
  @doc """
  Retorna o evento para operação de update no repositório.
  
  ## Retorno
  
    * `[:deeper_hub, :repository, :update]` - Evento para operação de update
  """
  @spec repository_update() :: [atom()]
  def repository_update, do: @repository_prefix ++ [:update]
  
  @doc """
  Retorna o evento para operação de delete no repositório.
  
  ## Retorno
  
    * `[:deeper_hub, :repository, :delete]` - Evento para operação de delete
  """
  @spec repository_delete() :: [atom()]
  def repository_delete, do: @repository_prefix ++ [:delete]
  
  # Eventos relacionados ao sistema HTTP
  @http_prefix @base_prefix ++ [:http]
  
  @doc """
  Retorna o prefixo base para eventos HTTP.
  
  ## Retorno
  
    * `[:deeper_hub, :http]` - Prefixo para eventos HTTP
  """
  @spec http() :: [atom()]
  def http, do: @http_prefix
  
  @doc """
  Retorna o evento para requisição HTTP.
  
  ## Retorno
  
    * `[:deeper_hub, :http, :request]` - Evento para requisição HTTP
  """
  @spec http_request() :: [atom()]
  def http_request, do: @http_prefix ++ [:request]
  
  @doc """
  Retorna o evento para resposta HTTP.
  
  ## Retorno
  
    * `[:deeper_hub, :http, :response]` - Evento para resposta HTTP
  """
  @spec http_response() :: [atom()]
  def http_response, do: @http_prefix ++ [:response]
  
  # Eventos relacionados ao sistema de autenticação
  @auth_prefix @base_prefix ++ [:auth]
  
  @doc """
  Retorna o prefixo base para eventos de autenticação.
  
  ## Retorno
  
    * `[:deeper_hub, :auth]` - Prefixo para eventos de autenticação
  """
  @spec auth() :: [atom()]
  def auth, do: @auth_prefix
  
  @doc """
  Retorna o evento para login.
  
  ## Retorno
  
    * `[:deeper_hub, :auth, :login]` - Evento para login
  """
  @spec auth_login() :: [atom()]
  def auth_login, do: @auth_prefix ++ [:login]
  
  @doc """
  Retorna o evento para logout.
  
  ## Retorno
  
    * `[:deeper_hub, :auth, :logout]` - Evento para logout
  """
  @spec auth_logout() :: [atom()]
  def auth_logout, do: @auth_prefix ++ [:logout]
  
  @doc """
  Retorna o evento para falha de autenticação.
  
  ## Retorno
  
    * `[:deeper_hub, :auth, :failure]` - Evento para falha de autenticação
  """
  @spec auth_failure() :: [atom()]
  def auth_failure, do: @auth_prefix ++ [:failure]
  
  # Funções auxiliares para ações comuns
  
  @doc """
  Adiciona a ação de início a um prefixo de evento.
  
  ## Parâmetros
  
    * `event_prefix` - Prefixo do evento
    
  ## Retorno
  
    * `event_prefix ++ [:start]` - Evento de início
  """
  @spec start(event_prefix :: [atom()]) :: [atom()]
  def start(event_prefix), do: event_prefix ++ [:start]
  
  @doc """
  Adiciona a ação de fim a um prefixo de evento.
  
  ## Parâmetros
  
    * `event_prefix` - Prefixo do evento
    
  ## Retorno
  
    * `event_prefix ++ [:stop]` - Evento de fim
  """
  @spec stop(event_prefix :: [atom()]) :: [atom()]
  def stop(event_prefix), do: event_prefix ++ [:stop]
  
  @doc """
  Adiciona a ação de exceção a um prefixo de evento.
  
  ## Parâmetros
  
    * `event_prefix` - Prefixo do evento
    
  ## Retorno
  
    * `event_prefix ++ [:exception]` - Evento de exceção
  """
  @spec exception(event_prefix :: [atom()]) :: [atom()]
  def exception(event_prefix), do: event_prefix ++ [:exception]
end
