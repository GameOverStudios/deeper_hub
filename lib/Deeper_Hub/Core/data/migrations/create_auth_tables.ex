defmodule DeeperHub.Core.Data.Migrations.CreateAuthTables do
  @moduledoc """
  Migração para criar as tabelas necessárias para autenticação e gerenciamento de usuários.
  
  Esta migração cria as seguintes tabelas:
  - user_sessions: para gerenciamento de sessões de usuário
  - user_devices: para gerenciamento de dispositivos confiáveis
  - user_activity_logs: para registro de atividades do usuário
  - user_preferences: para preferências e configurações de usuário
  - user_roles: para papéis e permissões de usuário
  - account_deletion_requests: para solicitações de exclusão de conta
  - password_reset_tokens: para tokens de recuperação de senha
  - user_tokens: para armazenamento e gerenciamento de tokens JWT
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Aplica a migração, criando as tabelas necessárias.
  """
  def up do
    Logger.info("Aplicando migração CreateAuthTables", module: __MODULE__)
    
    # Cria a tabela de sessões de usuário
    create_user_sessions_table()
    
    # Cria a tabela de dispositivos de usuário
    create_user_devices_table()
    
    # Cria a tabela de logs de atividade
    create_user_activity_logs_table()
    
    # Cria a tabela de preferências de usuário
    create_user_preferences_table()
    
    # Cria a tabela de papéis de usuário
    create_user_roles_table()
    
    # Cria a tabela de solicitações de exclusão de conta
    create_account_deletion_requests_table()
    
    # Cria a tabela de tokens de recuperação de senha
    create_password_reset_tokens_table()
    
    # Cria a tabela de tokens JWT
    create_user_tokens_table()
    
    # Atualiza a tabela de usuários para adicionar o campo two_factor_enabled
    update_users_table()
    
    :ok
  end
  
  @doc """
  Reverte a migração, removendo as tabelas criadas.
  """
  def down do
    Logger.info("Revertendo migração CreateAuthTables", module: __MODULE__)
    
    # Remove as tabelas na ordem inversa
    Repo.execute("DROP TABLE IF EXISTS user_tokens;", [])
    Repo.execute("DROP TABLE IF EXISTS password_reset_tokens;", [])
    Repo.execute("DROP TABLE IF EXISTS account_deletion_requests;", [])
    Repo.execute("DROP TABLE IF EXISTS user_roles;", [])
    Repo.execute("DROP TABLE IF EXISTS user_preferences;", [])
    Repo.execute("DROP TABLE IF EXISTS user_activity_logs;", [])
    Repo.execute("DROP TABLE IF EXISTS user_devices;", [])
    Repo.execute("DROP TABLE IF EXISTS user_sessions;", [])
    
    # Remove o campo two_factor_enabled da tabela de usuários
    Repo.execute("ALTER TABLE users DROP COLUMN two_factor_enabled;", [])
    
    :ok
  end
  
  # Funções privadas para criar cada tabela
  
  defp create_user_sessions_table do
    sql = """
    CREATE TABLE IF NOT EXISTS user_sessions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      browser TEXT,
      os TEXT,
      ip_address TEXT,
      location TEXT,
      active BOOLEAN DEFAULT TRUE,
      last_activity TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
    """
    
    case Repo.execute(sql, []) do
      {:ok, _} ->
        Logger.info("Tabela user_sessions criada com sucesso", module: __MODULE__)
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao criar tabela user_sessions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  defp create_user_devices_table do
    sql = """
    CREATE TABLE IF NOT EXISTS user_devices (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      browser TEXT,
      os TEXT,
      ip_address TEXT,
      location TEXT,
      trusted BOOLEAN DEFAULT FALSE,
      last_used TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
    """
    
    case Repo.execute(sql, []) do
      {:ok, _} ->
        Logger.info("Tabela user_devices criada com sucesso", module: __MODULE__)
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao criar tabela user_devices: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  defp create_user_activity_logs_table do
    sql = """
    CREATE TABLE IF NOT EXISTS user_activity_logs (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      activity_type TEXT NOT NULL,
      metadata TEXT DEFAULT '{}',
      ip_address TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
    """
    
    case Repo.execute(sql, []) do
      {:ok, _} ->
        Logger.info("Tabela user_activity_logs criada com sucesso", module: __MODULE__)
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao criar tabela user_activity_logs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  defp create_user_preferences_table do
    sql = """
    CREATE TABLE IF NOT EXISTS user_preferences (
      user_id TEXT PRIMARY KEY,
      notification_preferences TEXT DEFAULT '{}',
      privacy_settings TEXT DEFAULT '{}',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
    """
    
    case Repo.execute(sql, []) do
      {:ok, _} ->
        Logger.info("Tabela user_preferences criada com sucesso", module: __MODULE__)
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao criar tabela user_preferences: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  defp create_user_roles_table do
    sql = """
    CREATE TABLE IF NOT EXISTS user_roles (
      user_id TEXT PRIMARY KEY,
      role TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
    """
    
    case Repo.execute(sql, []) do
      {:ok, _} ->
        Logger.info("Tabela user_roles criada com sucesso", module: __MODULE__)
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao criar tabela user_roles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  defp create_account_deletion_requests_table do
    sql = """
    CREATE TABLE IF NOT EXISTS account_deletion_requests (
      user_id TEXT NOT NULL,
      confirmation_token TEXT NOT NULL,
      reason TEXT DEFAULT '{}',
      status TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      PRIMARY KEY (user_id, confirmation_token),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
    """
    
    case Repo.execute(sql, []) do
      {:ok, _} ->
        Logger.info("Tabela account_deletion_requests criada com sucesso", module: __MODULE__)
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao criar tabela account_deletion_requests: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  defp create_password_reset_tokens_table do
    sql = """
    CREATE TABLE IF NOT EXISTS password_reset_tokens (
      token TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      used BOOLEAN DEFAULT FALSE,
      expires_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
    """
    
    case Repo.execute(sql, []) do
      {:ok, _} ->
        Logger.info("Tabela password_reset_tokens criada com sucesso", module: __MODULE__)
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao criar tabela password_reset_tokens: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  defp create_user_tokens_table do
    sql = """
    CREATE TABLE IF NOT EXISTS user_tokens (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      session_id TEXT,
      token TEXT NOT NULL,
      token_type TEXT NOT NULL,
      revoked BOOLEAN DEFAULT FALSE,
      expires_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (session_id) REFERENCES user_sessions(id) ON DELETE CASCADE
    );
    """
    
    case Repo.execute(sql, []) do
      {:ok, _} ->
        Logger.info("Tabela user_tokens criada com sucesso", module: __MODULE__)
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao criar tabela user_tokens: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  defp update_users_table do
    # Verifica se a coluna já existe
    check_sql = """
    SELECT COUNT(*) FROM pragma_table_info('users') WHERE name = 'two_factor_enabled';
    """
    
    case Repo.query(check_sql, []) do
      {:ok, %{rows: [[0]]}} ->
        # A coluna não existe, adiciona
        add_sql = "ALTER TABLE users ADD COLUMN two_factor_enabled BOOLEAN DEFAULT FALSE;"
        
        case Repo.execute(add_sql, []) do
          {:ok, _} ->
            Logger.info("Coluna two_factor_enabled adicionada à tabela users", module: __MODULE__)
            :ok
            
          {:error, reason} ->
            Logger.error("Erro ao adicionar coluna two_factor_enabled: #{inspect(reason)}", module: __MODULE__)
            {:error, reason}
        end
        
      {:ok, %{rows: [[_]]}} ->
        # A coluna já existe
        Logger.info("Coluna two_factor_enabled já existe na tabela users", module: __MODULE__)
        :ok
        
      {:error, reason} ->
        Logger.error("Erro ao verificar coluna two_factor_enabled: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
