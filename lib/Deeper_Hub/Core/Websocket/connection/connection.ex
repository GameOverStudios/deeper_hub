defmodule Deeper_Hub.Core.Websocket.Connection do
  @moduledoc """
  Módulo de fachada (Facade) para componentes de conexão WebSocket.
  
  Este módulo:
  - Centraliza acesso aos componentes de conexão
  - Fornece uma API unificada para gerenciamento de conexões
  - Encapsula a implementação de monitoramento e presença
  """
  
  alias Deeper_Hub.Core.Websocket.Connection.ConnectionMonitor
  alias Deeper_Hub.Core.Websocket.Connection.Presence
  alias Deeper_Hub.Core.Websocket.Connection.Socket
  
  @doc """
  Inicializa o monitoramento de uma conexão.
  
  ## Parâmetros
  
  - `socket`: Socket Phoenix a ser monitorado
  
  ## Retorno
  
  - `{:ok, pid}`: PID do processo de monitoramento
  - `{:error, reason}`: Erro ao iniciar monitoramento
  """
  defdelegate monitor_connection(socket), to: ConnectionMonitor, as: :start_monitoring
  
  @doc """
  Registra a presença de um usuário.
  
  ## Parâmetros
  
  - `socket`: Socket Phoenix
  - `user_id`: ID do usuário
  - `metadata`: Metadados adicionais (opcional)
  
  ## Retorno
  
  - `:ok`: Presença registrada com sucesso
  """
  def track_presence(socket, user_id, metadata \\ %{}) do
    Presence.track(socket, user_id, metadata)
  end
  
  @doc """
  Lista usuários presentes no canal.
  
  ## Retorno
  
  - Mapa de usuários presentes e seus metadados
  """
  def list_present_users do
    Presence.list("websocket")
  end
  
  @doc """
  Verifica se um socket é válido e ativo.
  
  ## Parâmetros
  
  - `socket`: Socket Phoenix a ser verificado
  
  ## Retorno
  
  - `true`: Socket válido e ativo
  - `false`: Socket inválido ou inativo
  """
  def valid_socket?(socket) do
    Socket.valid?(socket)
  end
end
