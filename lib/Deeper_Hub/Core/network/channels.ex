defmodule DeeperHub.Core.Network.Channels do
  @moduledoc """
  Módulo de fachada para operações com canais de comunicação.

  Este módulo fornece uma interface simplificada para interagir com os canais
  de comunicação, abstraindo a complexidade da implementação subjacente.
  """

  alias DeeperHub.Core.Network.Channels.Channel
  require DeeperHub.Core.Logger

  @doc """
  Cria um novo canal de comunicação.

  ## Parâmetros

  - `name` - Nome do canal
  - `owner_id` - ID do proprietário do canal
  - `opts` - Opções adicionais para o canal

  ## Retorno

  - `{:ok, channel_id}` - Canal criado com sucesso
  - `{:error, reason}` - Falha ao criar o canal
  """
  def create(name, owner_id, opts \\ []) do
    Channel.create(name, owner_id, opts)
  end

  @doc """
  Obtém informações sobre um canal.

  ## Parâmetros

  - `channel_id` - ID do canal

  ## Retorno

  - `{:ok, info}` - Informações do canal
  - `{:error, reason}` - Falha ao obter informações
  """
  def info(channel_id) do
    Channel.info(channel_id)
  end

  @doc """
  Assina um canal para receber mensagens.

  ## Parâmetros

  - `channel_id` - ID do canal
  - `connection_id` - ID da conexão do assinante
  - `metadata` - Metadados adicionais do assinante

  ## Retorno

  - `:ok` - Assinatura criada com sucesso
  - `{:error, reason}` - Falha ao criar a assinatura
  """
  def subscribe(channel_id, connection_id, metadata \\ %{}) do
    Channel.subscribe(channel_id, connection_id, metadata)
  end

  @doc """
  Cancela a assinatura de um canal.

  ## Parâmetros

  - `channel_id` - ID do canal
  - `connection_id` - ID da conexão do assinante

  ## Retorno

  - `:ok` - Assinatura cancelada com sucesso
  - `{:error, reason}` - Falha ao cancelar a assinatura
  """
  def unsubscribe(channel_id, connection_id) do
    Channel.unsubscribe(channel_id, connection_id)
  end

  @doc """
  Envia uma mensagem para todos os assinantes de um canal.

  ## Parâmetros

  - `channel_id` - ID do canal
  - `message` - Mensagem a ser enviada

  ## Retorno

  - `:ok` - Mensagem enviada com sucesso
  - `{:error, reason}` - Falha ao enviar a mensagem
  """
  def broadcast(channel_id, message) do
    case Channel.publish(channel_id, "system", message, type: "broadcast") do
      {:ok, _} -> :ok
      error -> error
    end
  end

  @doc """
  Lista todos os canais disponíveis.

  ## Retorno

  - `{:ok, channels}` - Lista de canais disponíveis
  - `{:error, reason}` - Falha ao listar os canais
  """
  def list do
    Channel.list()
  end

  @doc """
  Remove um canal.

  ## Parâmetros

  - `channel_id` - ID do canal
  - `owner_id` - ID do proprietário do canal (para verificação)

  ## Retorno

  - `:ok` - Canal removido com sucesso
  - `{:error, reason}` - Falha ao remover o canal
  """
  def remove(channel_id, owner_id) do
    Channel.remove(channel_id, owner_id)
  end
end
