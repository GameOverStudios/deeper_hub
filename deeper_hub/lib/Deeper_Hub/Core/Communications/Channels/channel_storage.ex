defmodule Deeper_Hub.Core.Communications.Channels.ChannelStorage do
  @moduledoc """
  Armazenamento persistente para canais e suas mensagens.
  
  Este módulo gerencia o armazenamento e recuperação de canais e mensagens
  no banco de dados.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.DBConnection.Facade, as: DB
  
  @doc """
  Salva um canal no banco de dados.
  
  ## Parâmetros
  
    - `channel`: O canal a ser salvo
  
  ## Retorno
  
    - `{:ok, channel_id}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def save_channel(channel) do
    Logger.debug("Salvando canal no banco de dados", %{
      module: __MODULE__,
      channel_id: channel.id,
      channel_name: channel.name
    })
    
    query = """
    INSERT INTO channels (
      id, name, creator_id, created_at, metadata
    ) VALUES (?, ?, ?, ?, ?)
    """
    
    metadata_json = Jason.encode!(channel.metadata)
    
    params = [
      channel.id,
      channel.name,
      channel.creator_id,
      channel.created_at,
      metadata_json
    ]
    
    case DB.query(query, params) do
      {:ok, _} ->
        {:ok, channel.id}
      {:error, reason} ->
        Logger.error("Erro ao salvar canal", %{
          module: __MODULE__,
          channel_id: channel.id,
          channel_name: channel.name,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Salva uma mensagem de canal no banco de dados.
  
  ## Parâmetros
  
    - `message`: A mensagem a ser salva
  
  ## Retorno
  
    - `{:ok, message_id}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def save_message(message) do
    Logger.debug("Salvando mensagem de canal no banco de dados", %{
      module: __MODULE__,
      message_id: message.id,
      channel_name: message.channel_name
    })
    
    query = """
    INSERT INTO channel_messages (
      id, channel_name, sender_id, content, metadata, timestamp
    ) VALUES (?, ?, ?, ?, ?, ?)
    """
    
    metadata_json = Jason.encode!(message.metadata)
    
    params = [
      message.id,
      message.channel_name,
      message.sender_id,
      message.content,
      metadata_json,
      message.timestamp
    ]
    
    case DB.query(query, params) do
      {:ok, _} ->
        {:ok, message.id}
      {:error, reason} ->
        Logger.error("Erro ao salvar mensagem de canal", %{
          module: __MODULE__,
          message_id: message.id,
          channel_name: message.channel_name,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Salva uma inscrição de usuário em um canal.
  
  ## Parâmetros
  
    - `channel_name`: Nome do canal
    - `user_id`: ID do usuário
  
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def save_subscription(channel_name, user_id) do
    Logger.debug("Salvando inscrição de usuário em canal", %{
      module: __MODULE__,
      channel_name: channel_name,
      user_id: user_id
    })
    
    query = """
    INSERT INTO channel_subscriptions (
      channel_name, user_id, subscribed_at
    ) VALUES (?, ?, ?)
    """
    
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    
    params = [
      channel_name,
      user_id,
      timestamp
    ]
    
    case DB.query(query, params) do
      {:ok, _} ->
        :ok
      {:error, reason} ->
        Logger.error("Erro ao salvar inscrição em canal", %{
          module: __MODULE__,
          channel_name: channel_name,
          user_id: user_id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Remove uma inscrição de usuário em um canal.
  
  ## Parâmetros
  
    - `channel_name`: Nome do canal
    - `user_id`: ID do usuário
  
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def remove_subscription(channel_name, user_id) do
    Logger.debug("Removendo inscrição de usuário em canal", %{
      module: __MODULE__,
      channel_name: channel_name,
      user_id: user_id
    })
    
    query = """
    DELETE FROM channel_subscriptions
    WHERE channel_name = ? AND user_id = ?
    """
    
    params = [channel_name, user_id]
    
    case DB.query(query, params) do
      {:ok, _} ->
        :ok
      {:error, reason} ->
        Logger.error("Erro ao remover inscrição em canal", %{
          module: __MODULE__,
          channel_name: channel_name,
          user_id: user_id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Obtém um canal pelo nome.
  
  ## Parâmetros
  
    - `channel_name`: Nome do canal
  
  ## Retorno
  
    - `{:ok, channel}` em caso de sucesso
    - `{:error, :not_found}` se o canal não for encontrado
    - `{:error, reason}` em caso de falha
  """
  def get_channel(channel_name) do
    Logger.debug("Buscando canal no banco de dados", %{
      module: __MODULE__,
      channel_name: channel_name
    })
    
    query = """
    SELECT id, name, creator_id, created_at, metadata
    FROM channels
    WHERE name = ?
    """
    
    case DB.query(query, [channel_name]) do
      {:ok, %{rows: [row]}} ->
        channel = parse_channel_row(row)
        {:ok, channel}
        
      {:ok, %{rows: []}} ->
        {:error, :not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar canal", %{
          module: __MODULE__,
          channel_name: channel_name,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Obtém mensagens de um canal.
  
  ## Parâmetros
  
    - `channel_name`: Nome do canal
    - `limit`: Número máximo de mensagens
    - `offset`: Deslocamento para paginação
  
  ## Retorno
  
    - `{:ok, messages}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def get_channel_messages(channel_name, limit, offset) do
    Logger.debug("Buscando mensagens de canal no banco de dados", %{
      module: __MODULE__,
      channel_name: channel_name,
      limit: limit,
      offset: offset
    })
    
    query = """
    SELECT id, channel_name, sender_id, content, metadata, timestamp
    FROM channel_messages
    WHERE channel_name = ?
    ORDER BY timestamp DESC
    LIMIT ? OFFSET ?
    """
    
    params = [channel_name, limit, offset]
    
    case DB.query(query, params) do
      {:ok, %{rows: rows}} ->
        messages = Enum.map(rows, &parse_message_row/1)
        {:ok, messages}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar mensagens de canal", %{
          module: __MODULE__,
          channel_name: channel_name,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Lista os canais disponíveis.
  
  ## Parâmetros
  
    - `limit`: Número máximo de canais
    - `offset`: Deslocamento para paginação
  
  ## Retorno
  
    - `{:ok, channels}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def list_channels(limit, offset) do
    Logger.debug("Listando canais no banco de dados", %{
      module: __MODULE__,
      limit: limit,
      offset: offset
    })
    
    query = """
    SELECT c.id, c.name, c.creator_id, c.created_at, c.metadata,
           COUNT(DISTINCT cs.user_id) as subscriber_count,
           COUNT(DISTINCT cm.id) as message_count
    FROM channels c
    LEFT JOIN channel_subscriptions cs ON c.name = cs.channel_name
    LEFT JOIN channel_messages cm ON c.name = cm.channel_name
    GROUP BY c.id
    ORDER BY c.created_at DESC
    LIMIT ? OFFSET ?
    """
    
    params = [limit, offset]
    
    case DB.query(query, params) do
      {:ok, %{rows: rows}} ->
        channels = Enum.map(rows, fn row ->
          [id, name, creator_id, created_at, metadata_json, subscriber_count, message_count] = row
          
          # Decodifica o JSON de metadados
          metadata = case Jason.decode(metadata_json) do
            {:ok, decoded} -> decoded
            _ -> %{}
          end
          
          %{
            id: id,
            name: name,
            creator_id: creator_id,
            created_at: created_at,
            metadata: metadata,
            subscriber_count: subscriber_count,
            message_count: message_count
          }
        end)
        
        {:ok, channels}
        
      {:error, reason} ->
        Logger.error("Erro ao listar canais", %{
          module: __MODULE__,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Lista os canais que um usuário está inscrito.
  
  ## Parâmetros
  
    - `user_id`: ID do usuário
  
  ## Retorno
  
    - `{:ok, channels}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def list_user_subscriptions(user_id) do
    Logger.debug("Listando inscrições de usuário", %{
      module: __MODULE__,
      user_id: user_id
    })
    
    query = """
    SELECT c.id, c.name, c.creator_id, c.created_at, c.metadata,
           COUNT(DISTINCT cs2.user_id) as subscriber_count,
           COUNT(DISTINCT cm.id) as message_count,
           cs.subscribed_at
    FROM channel_subscriptions cs
    JOIN channels c ON cs.channel_name = c.name
    LEFT JOIN channel_subscriptions cs2 ON c.name = cs2.channel_name
    LEFT JOIN channel_messages cm ON c.name = cm.channel_name
    WHERE cs.user_id = ?
    GROUP BY c.id
    ORDER BY cs.subscribed_at DESC
    """
    
    params = [user_id]
    
    case DB.query(query, params) do
      {:ok, %{rows: rows}} ->
        channels = Enum.map(rows, fn row ->
          [id, name, creator_id, created_at, metadata_json, subscriber_count, message_count, subscribed_at] = row
          
          # Decodifica o JSON de metadados
          metadata = case Jason.decode(metadata_json) do
            {:ok, decoded} -> decoded
            _ -> %{}
          end
          
          %{
            id: id,
            name: name,
            creator_id: creator_id,
            created_at: created_at,
            metadata: metadata,
            subscriber_count: subscriber_count,
            message_count: message_count,
            subscribed_at: subscribed_at
          }
        end)
        
        {:ok, channels}
        
      {:error, reason} ->
        Logger.error("Erro ao listar inscrições de usuário", %{
          module: __MODULE__,
          user_id: user_id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Cria as tabelas necessárias para canais se elas não existirem.
  
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def create_tables_if_not_exist do
    Logger.info("Criando tabelas de canais se não existirem", %{module: __MODULE__})
    
    # Tabela de canais
    channel_query = """
    CREATE TABLE IF NOT EXISTS channels (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      creator_id TEXT NOT NULL,
      created_at TEXT NOT NULL,
      metadata TEXT
    )
    """
    
    # Tabela de mensagens de canais
    message_query = """
    CREATE TABLE IF NOT EXISTS channel_messages (
      id TEXT PRIMARY KEY,
      channel_name TEXT NOT NULL,
      sender_id TEXT NOT NULL,
      content TEXT NOT NULL,
      metadata TEXT,
      timestamp TEXT NOT NULL,
      FOREIGN KEY (channel_name) REFERENCES channels(name)
    )
    """
    
    # Tabela de inscrições em canais
    subscription_query = """
    CREATE TABLE IF NOT EXISTS channel_subscriptions (
      channel_name TEXT NOT NULL,
      user_id TEXT NOT NULL,
      subscribed_at TEXT NOT NULL,
      PRIMARY KEY (channel_name, user_id),
      FOREIGN KEY (channel_name) REFERENCES channels(name)
    )
    """
    
    case DB.query(channel_query) do
      {:ok, _} ->
        case DB.query(message_query) do
          {:ok, _} ->
            case DB.query(subscription_query) do
              {:ok, _} ->
                # Cria índices para melhorar o desempenho
                create_indexes()
              {:error, reason} ->
                Logger.error("Erro ao criar tabela de inscrições em canais", %{
                  module: __MODULE__,
                  error: reason
                })
                
                {:error, reason}
            end
          {:error, reason} ->
            Logger.error("Erro ao criar tabela de mensagens de canais", %{
              module: __MODULE__,
              error: reason
            })
            
            {:error, reason}
        end
      {:error, reason} ->
        Logger.error("Erro ao criar tabela de canais", %{
          module: __MODULE__,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  # Funções auxiliares
  
  # Cria índices para as tabelas
  defp create_indexes do
    # Índice para buscar canais por nome
    DB.query("CREATE INDEX IF NOT EXISTS idx_channels_name ON channels (name)")
    
    # Índice para buscar mensagens por canal
    DB.query("CREATE INDEX IF NOT EXISTS idx_channel_messages_channel ON channel_messages (channel_name)")
    
    # Índice para ordenar mensagens por timestamp
    DB.query("CREATE INDEX IF NOT EXISTS idx_channel_messages_timestamp ON channel_messages (timestamp)")
    
    # Índice para buscar inscrições por usuário
    DB.query("CREATE INDEX IF NOT EXISTS idx_channel_subscriptions_user ON channel_subscriptions (user_id)")
    
    :ok
  end
  
  # Converte uma linha do banco de dados para um mapa de canal
  defp parse_channel_row(row) do
    [id, name, creator_id, created_at, metadata_json] = row
    
    # Decodifica o JSON de metadados
    metadata = case Jason.decode(metadata_json) do
      {:ok, decoded} -> decoded
      _ -> %{}
    end
    
    %{
      id: id,
      name: name,
      creator_id: creator_id,
      created_at: created_at,
      metadata: metadata
    }
  end
  
  # Converte uma linha do banco de dados para um mapa de mensagem
  defp parse_message_row(row) do
    [id, channel_name, sender_id, content, metadata_json, timestamp] = row
    
    # Decodifica o JSON de metadados
    metadata = case Jason.decode(metadata_json) do
      {:ok, decoded} -> decoded
      _ -> %{}
    end
    
    %{
      id: id,
      channel_name: channel_name,
      sender_id: sender_id,
      content: content,
      metadata: metadata,
      timestamp: timestamp
    }
  end
end
