defmodule Deeper_Hub.Core.EventBus.Topics do
  @moduledoc """
  Define os tópicos padrão para o barramento de eventos do sistema DeeperHub.
  
  Este módulo centraliza a definição de todos os tópicos de eventos
  utilizados no sistema, garantindo consistência e evitando duplicação
  de nomes de tópicos em diferentes partes da aplicação.
  
  ## Estrutura de Tópicos
  
  Os tópicos são organizados por domínio de negócio:
  
  * `:user` - Eventos relacionados a usuários
  * `:auth` - Eventos relacionados a autenticação
  * `:content` - Eventos relacionados a conteúdo
  * `:notification` - Eventos relacionados a notificações
  * `:system` - Eventos relacionados ao sistema
  
  ## Exemplo de Uso
  
  ```elixir
  alias Deeper_Hub.Core.EventBus.Topics
  alias Deeper_Hub.Core.EventBus.EventBusFacade
  
  # Registrar um tópico padrão
  EventBusFacade.register_topic(Topics.user_registered())
  
  # Publicar um evento em um tópico padrão
  EventBusFacade.publish(
    Topics.user_registered(),
    %{id: 123, email: "user@example.com"}
  )
  ```
  """
  
  # Tópicos relacionados a usuários
  @doc """
  Tópico para evento de usuário registrado.
  
  ## Retorno
  
    * `:user_registered` - Tópico para evento de usuário registrado
  """
  @spec user_registered() :: atom()
  def user_registered, do: :user_registered
  
  @doc """
  Tópico para evento de usuário atualizado.
  
  ## Retorno
  
    * `:user_updated` - Tópico para evento de usuário atualizado
  """
  @spec user_updated() :: atom()
  def user_updated, do: :user_updated
  
  @doc """
  Tópico para evento de usuário removido.
  
  ## Retorno
  
    * `:user_removed` - Tópico para evento de usuário removido
  """
  @spec user_removed() :: atom()
  def user_removed, do: :user_removed
  
  # Tópicos relacionados a autenticação
  @doc """
  Tópico para evento de login.
  
  ## Retorno
  
    * `:user_logged_in` - Tópico para evento de login
  """
  @spec user_logged_in() :: atom()
  def user_logged_in, do: :user_logged_in
  
  @doc """
  Tópico para evento de logout.
  
  ## Retorno
  
    * `:user_logged_out` - Tópico para evento de logout
  """
  @spec user_logged_out() :: atom()
  def user_logged_out, do: :user_logged_out
  
  @doc """
  Tópico para evento de falha de autenticação.
  
  ## Retorno
  
    * `:auth_failed` - Tópico para evento de falha de autenticação
  """
  @spec auth_failed() :: atom()
  def auth_failed, do: :auth_failed
  
  @doc """
  Tópico para evento de redefinição de senha solicitada.
  
  ## Retorno
  
    * `:password_reset_requested` - Tópico para evento de redefinição de senha solicitada
  """
  @spec password_reset_requested() :: atom()
  def password_reset_requested, do: :password_reset_requested
  
  # Tópicos relacionados a conteúdo
  @doc """
  Tópico para evento de conteúdo criado.
  
  ## Retorno
  
    * `:content_created` - Tópico para evento de conteúdo criado
  """
  @spec content_created() :: atom()
  def content_created, do: :content_created
  
  @doc """
  Tópico para evento de conteúdo atualizado.
  
  ## Retorno
  
    * `:content_updated` - Tópico para evento de conteúdo atualizado
  """
  @spec content_updated() :: atom()
  def content_updated, do: :content_updated
  
  @doc """
  Tópico para evento de conteúdo removido.
  
  ## Retorno
  
    * `:content_removed` - Tópico para evento de conteúdo removido
  """
  @spec content_removed() :: atom()
  def content_removed, do: :content_removed
  
  # Tópicos relacionados a notificações
  @doc """
  Tópico para evento de notificação criada.
  
  ## Retorno
  
    * `:notification_created` - Tópico para evento de notificação criada
  """
  @spec notification_created() :: atom()
  def notification_created, do: :notification_created
  
  @doc """
  Tópico para evento de notificação enviada.
  
  ## Retorno
  
    * `:notification_sent` - Tópico para evento de notificação enviada
  """
  @spec notification_sent() :: atom()
  def notification_sent, do: :notification_sent
  
  @doc """
  Tópico para evento de notificação lida.
  
  ## Retorno
  
    * `:notification_read` - Tópico para evento de notificação lida
  """
  @spec notification_read() :: atom()
  def notification_read, do: :notification_read
  
  # Tópicos relacionados ao sistema
  @doc """
  Tópico para evento de sistema iniciado.
  
  ## Retorno
  
    * `:system_started` - Tópico para evento de sistema iniciado
  """
  @spec system_started() :: atom()
  def system_started, do: :system_started
  
  @doc """
  Tópico para evento de sistema parado.
  
  ## Retorno
  
    * `:system_stopped` - Tópico para evento de sistema parado
  """
  @spec system_stopped() :: atom()
  def system_stopped, do: :system_stopped
  
  @doc """
  Tópico para evento de erro de sistema.
  
  ## Retorno
  
    * `:system_error` - Tópico para evento de erro de sistema
  """
  @spec system_error() :: atom()
  def system_error, do: :system_error
  
  @doc """
  Registra todos os tópicos padrão no barramento de eventos.
  
  ## Retorno
  
    * `:ok` - Todos os tópicos foram registrados com sucesso
    * `{:error, reason}` - Falha ao registrar um ou mais tópicos
  """
  @spec register_all_topics() :: :ok | {:error, term()}
  def register_all_topics do
    alias Deeper_Hub.Core.EventBus.EventBusFacade
    
    # Lista de todos os tópicos padrão
    topics = [
      # Usuários
      user_registered(),
      user_updated(),
      user_removed(),
      
      # Autenticação
      user_logged_in(),
      user_logged_out(),
      auth_failed(),
      password_reset_requested(),
      
      # Conteúdo
      content_created(),
      content_updated(),
      content_removed(),
      
      # Notificações
      notification_created(),
      notification_sent(),
      notification_read(),
      
      # Sistema
      system_started(),
      system_stopped(),
      system_error()
    ]
    
    # Registra cada tópico
    Enum.each(topics, fn topic ->
      EventBusFacade.register_topic(topic)
    end)
    
    :ok
  end
end
