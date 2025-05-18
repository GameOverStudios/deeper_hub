defmodule Deeper_Hub.Core.Communications.Messages.MessageStorage do
  @moduledoc """
  Armazenamento persistente de mensagens.
  
  Este módulo gerencia o armazenamento e recuperação de mensagens
  no banco de dados.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.DBConnection.Facade, as: DB
  
  @doc """
  Salva uma mensagem no banco de dados.
  
  ## Parâmetros
  
    - `message`: A mensagem a ser salva
  
  ## Retorno
  
    - `{:ok, message_id}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def save_message(message) do
    Logger.debug("Salvando mensagem no banco de dados", %{
      module: __MODULE__,
      message_id: message.id
    })
    
    query = """
    INSERT INTO messages (
      id, sender_id, recipient_id, content, metadata, 
      timestamp, read, read_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """
    
    metadata_json = Jason.encode!(message.metadata)
    
    params = [
      message.id,
      message.sender_id,
      message.recipient_id,
      message.content,
      metadata_json,
      message.timestamp,
      message.read,
      message.read_at
    ]
    
    case DB.query(query, params) do
      {:ok, _} ->
        {:ok, message.id}
      {:error, reason} ->
        Logger.error("Erro ao salvar mensagem", %{
          module: __MODULE__,
          message_id: message.id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Marca uma mensagem como lida no banco de dados.
  
  ## Parâmetros
  
    - `message_id`: ID da mensagem
    - `read_at`: Timestamp de leitura
  
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def mark_as_read(message_id, read_at) do
    Logger.debug("Marcando mensagem como lida no banco de dados", %{
      module: __MODULE__,
      message_id: message_id
    })
    
    query = """
    UPDATE messages SET read = ?, read_at = ? WHERE id = ?
    """
    
    params = [true, read_at, message_id]
    
    case DB.query(query, params) do
      {:ok, _} ->
        :ok
      {:error, reason} ->
        Logger.error("Erro ao marcar mensagem como lida", %{
          module: __MODULE__,
          message_id: message_id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Obtém uma mensagem pelo ID.
  
  ## Parâmetros
  
    - `message_id`: ID da mensagem
  
  ## Retorno
  
    - `{:ok, message}` em caso de sucesso
    - `{:error, :not_found}` se a mensagem não for encontrada
    - `{:error, reason}` em caso de falha
  """
  def get_message(message_id) do
    Logger.debug("Buscando mensagem no banco de dados", %{
      module: __MODULE__,
      message_id: message_id
    })
    
    query = """
    SELECT id, sender_id, recipient_id, content, metadata,
           timestamp, read, read_at
    FROM messages
    WHERE id = ?
    """
    
    case DB.query(query, [message_id]) do
      {:ok, %{rows: [row]}} ->
        message = parse_message_row(row)
        {:ok, message}
        
      {:ok, %{rows: []}} ->
        {:error, :not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar mensagem", %{
          module: __MODULE__,
          message_id: message_id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Obtém o histórico de mensagens entre dois usuários.
  
  ## Parâmetros
  
    - `user1_id`: ID do primeiro usuário
    - `user2_id`: ID do segundo usuário
    - `limit`: Número máximo de mensagens
    - `offset`: Deslocamento para paginação
  
  ## Retorno
  
    - `{:ok, messages}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def get_conversation(user1_id, user2_id, limit, offset) do
    Logger.debug("Buscando conversa no banco de dados", %{
      module: __MODULE__,
      user1_id: user1_id,
      user2_id: user2_id,
      limit: limit,
      offset: offset
    })
    
    query = """
    SELECT id, sender_id, recipient_id, content, metadata,
           timestamp, read, read_at
    FROM messages
    WHERE (sender_id = ? AND recipient_id = ?) OR
          (sender_id = ? AND recipient_id = ?)
    ORDER BY timestamp DESC
    LIMIT ? OFFSET ?
    """
    
    params = [user1_id, user2_id, user2_id, user1_id, limit, offset]
    
    case DB.query(query, params) do
      {:ok, %{rows: rows}} ->
        messages = Enum.map(rows, &parse_message_row/1)
        {:ok, messages}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar conversa", %{
          module: __MODULE__,
          user1_id: user1_id,
          user2_id: user2_id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Obtém as conversas recentes de um usuário.
  
  ## Parâmetros
  
    - `user_id`: ID do usuário
    - `limit`: Número máximo de conversas
  
  ## Retorno
  
    - `{:ok, conversations}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def get_recent_conversations(user_id, limit) do
    Logger.debug("Buscando conversas recentes no banco de dados", %{
      module: __MODULE__,
      user_id: user_id,
      limit: limit
    })
    
    # Esta consulta é mais complexa:
    # 1. Subconsulta para obter a última mensagem de cada conversa
    # 2. Join para obter os detalhes da mensagem
    # 3. Contagem de mensagens não lidas
    query = """
    WITH last_messages AS (
      SELECT MAX(timestamp) as max_time, 
             CASE 
               WHEN sender_id = ? THEN recipient_id
               ELSE sender_id
             END as other_user_id
      FROM messages
      WHERE sender_id = ? OR recipient_id = ?
      GROUP BY other_user_id
    ),
    unread_counts AS (
      SELECT COUNT(*) as count, sender_id
      FROM messages
      WHERE recipient_id = ? AND read = 0
      GROUP BY sender_id
    )
    SELECT m.id, m.sender_id, m.recipient_id, m.content, m.metadata,
           m.timestamp, m.read, m.read_at,
           lm.other_user_id,
           COALESCE(uc.count, 0) as unread_count
    FROM messages m
    JOIN last_messages lm ON 
      m.timestamp = lm.max_time AND
      (m.sender_id = lm.other_user_id OR m.recipient_id = lm.other_user_id)
    LEFT JOIN unread_counts uc ON uc.sender_id = lm.other_user_id
    ORDER BY m.timestamp DESC
    LIMIT ?
    """
    
    params = [user_id, user_id, user_id, user_id, limit]
    
    case DB.query(query, params) do
      {:ok, %{rows: rows}} ->
        conversations = Enum.map(rows, fn row ->
          message = parse_message_row(Enum.slice(row, 0, 8))
          other_user_id = Enum.at(row, 8)
          unread_count = Enum.at(row, 9)
          
          %{
            user_id: other_user_id,
            last_message: message,
            unread_count: unread_count
          }
        end)
        
        {:ok, conversations}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar conversas recentes", %{
          module: __MODULE__,
          user_id: user_id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Obtém o número de mensagens não lidas para um usuário.
  
  ## Parâmetros
  
    - `user_id`: ID do usuário
  
  ## Retorno
  
    - `{:ok, count}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def get_unread_count(user_id) do
    Logger.debug("Contando mensagens não lidas no banco de dados", %{
      module: __MODULE__,
      user_id: user_id
    })
    
    query = """
    SELECT COUNT(*) FROM messages
    WHERE recipient_id = ? AND read = 0
    """
    
    case DB.query(query, [user_id]) do
      {:ok, %{rows: [[count]]}} ->
        {:ok, count}
        
      {:error, reason} ->
        Logger.error("Erro ao contar mensagens não lidas", %{
          module: __MODULE__,
          user_id: user_id,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Cria a tabela de mensagens se ela não existir.
  
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def create_table_if_not_exists do
    Logger.info("Criando tabela de mensagens se não existir", %{module: __MODULE__})
    
    query = """
    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      sender_id TEXT NOT NULL,
      recipient_id TEXT NOT NULL,
      content TEXT NOT NULL,
      metadata TEXT,
      timestamp TEXT NOT NULL,
      read INTEGER NOT NULL DEFAULT 0,
      read_at TEXT
    )
    """
    
    case DB.query(query) do
      {:ok, _} ->
        # Cria índices para melhorar o desempenho
        create_indexes()
      {:error, reason} ->
        Logger.error("Erro ao criar tabela de mensagens", %{
          module: __MODULE__,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  # Funções auxiliares
  
  # Cria índices para a tabela de mensagens
  defp create_indexes do
    # Índice para buscar mensagens por remetente
    DB.query("CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages (sender_id)")
    
    # Índice para buscar mensagens por destinatário
    DB.query("CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages (recipient_id)")
    
    # Índice para buscar mensagens não lidas
    DB.query("CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages (recipient_id, read)")
    
    # Índice para ordenar por timestamp
    DB.query("CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages (timestamp)")
    
    :ok
  end
  
  # Converte uma linha do banco de dados para um mapa de mensagem
  defp parse_message_row(row) do
    [id, sender_id, recipient_id, content, metadata_json, timestamp, read, read_at] = row
    
    # Decodifica o JSON de metadados
    metadata = case Jason.decode(metadata_json) do
      {:ok, decoded} -> decoded
      _ -> %{}
    end
    
    # Converte o valor booleano
    read_bool = read == 1
    
    %{
      id: id,
      sender_id: sender_id,
      recipient_id: recipient_id,
      content: content,
      metadata: metadata,
      timestamp: timestamp,
      read: read_bool,
      read_at: read_at
    }
  end
end
