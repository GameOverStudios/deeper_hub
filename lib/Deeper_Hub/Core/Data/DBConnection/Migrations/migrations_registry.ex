defmodule Deeper_Hub.Core.Data.DBConnection.Migrations.Registry do
  @moduledoc """
  Registro de migrações disponíveis para o sistema.
  
  Este módulo é responsável por registrar todas as migrações disponíveis
  para que sejam executadas automaticamente pelo sistema de migrações.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.DBConnection.Facade, as: DB
  alias Deeper_Hub.Core.Data.DBConnection.Migrations.Migration20250517000001_create_users_table
  
  @doc """
  Registra todas as migrações disponíveis.
  
  Esta função deve ser chamada durante a inicialização da aplicação
  para garantir que todas as migrações sejam executadas.
  """
  def register_migrations do
    Logger.info("Registrando migrações disponíveis", %{module: __MODULE__})
    
    # Garante que a tabela schema_migrations exista
    ensure_migrations_table()
    
    # Executa a migração para criar a tabela de usuários
    # Isso garante que a tabela exista antes de executar as migrações
    Migration20250517000001_create_users_table.up()
    
    # Registra a migração na tabela schema_migrations
    register_migration("20250517000001")
    
    :ok
  end
  
  @doc """
  Registra uma migração específica na tabela schema_migrations.
  
  ## Parâmetros
  
    - `version`: Versão da migração a ser registrada
  """
  def register_migration(version) do
    # Verifica se a migração já está registrada
    query = "SELECT 1 FROM schema_migrations WHERE version = ?"
    
    case DB.query(query, [version]) do
      {:ok, %{rows: []}} ->
        # Migração não registrada, registra
        insert_query = "INSERT INTO schema_migrations (version, inserted_at) VALUES (?, ?)"
        now = DateTime.utc_now() |> DateTime.to_string()
        
        case DB.query(insert_query, [version, now]) do
          {:ok, _} ->
            Logger.info("Migração #{version} registrada com sucesso", %{
              module: __MODULE__,
              version: version
            })
            :ok
          {:error, reason} ->
            Logger.error("Falha ao registrar migração #{version}", %{
              module: __MODULE__,
              version: version,
              error: reason
            })
            {:error, reason}
        end
      {:ok, _} ->
        # Migração já registrada
        Logger.info("Migração #{version} já registrada", %{
          module: __MODULE__,
          version: version
        })
        :ok
      {:error, _reason} ->
        # Provavelmente a tabela schema_migrations ainda não existe
        # Vamos garantir que ela exista e tentar novamente
        ensure_migrations_table()
        register_migration(version)
    end
  end
  
  # Garante que a tabela de migrações existe
  defp ensure_migrations_table() do
    # Verifica se a tabela de migrações existe
    query = """
    SELECT name FROM sqlite_master
    WHERE type='table' AND name='schema_migrations'
    """
    
    case DB.query(query, []) do
      {:ok, %{rows: []}} ->
        # Cria a tabela de migrações
        create_query = """
        CREATE TABLE schema_migrations (
          version TEXT PRIMARY KEY,
          inserted_at TEXT NOT NULL
        )
        """
        
        case DB.query(create_query, []) do
          {:ok, _} ->
            Logger.info("Tabela de migrações criada com sucesso", %{module: __MODULE__})
            :ok
          {:error, reason} ->
            Logger.error("Falha ao criar tabela de migrações", %{
              module: __MODULE__,
              error: reason
            })
            
            {:error, reason}
        end
      {:ok, _} ->
        # A tabela já existe
        :ok
      {:error, reason} ->
        Logger.error("Falha ao verificar existência da tabela de migrações", %{
          module: __MODULE__,
          error: reason
        })
        
        {:error, reason}
    end
  end
end
