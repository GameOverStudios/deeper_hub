defmodule DeeperHub.Core.EventManager.Config do
  @moduledoc """
  Módulo de configuração para o EventBus no DeeperHub.
  
  Este módulo é responsável por definir as configurações padrão e inicializar 
  os tópicos de eventos que serão utilizados na aplicação.
  """

  @doc """
  Define os tópicos padrão que serão registrados no EventBus.
  
  ## Retorno
  
  Lista de tópicos (atoms) que representam os tipos de eventos do sistema.
  """
  def default_topics do
    [
      # Eventos do sistema
      :system_started,
      :system_stopping,
      
      # Eventos de usuário
      :user_created,
      :user_updated,
      :user_deleted,
      :user_authenticated,
      :user_logout,
      
      # Eventos de dados
      :data_created,
      :data_updated,
      :data_deleted,
      
      # Eventos de integração
      :integration_succeeded,
      :integration_failed,
      
      # Eventos de notificação
      :notification_sent,
      :notification_failed
    ]
  end

  @doc """
  Inicializa os tópicos do EventBus.
  
  Registra todos os tópicos padrão no EventBus.
  
  ## Exemplos
  
      iex> DeeperHub.Core.EventManager.Config.initialize()
      :ok
  
  """
  def initialize do
    Enum.each(default_topics(), fn topic ->
      EventBus.register_topic(topic)
    end)
    
    :ok
  end
end
