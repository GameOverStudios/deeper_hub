defmodule Deeper_Hub.Core.Data.DBConnection.Migrations.Migration20250517000001_create_users_table do
  @moduledoc """
  Migração para criar a tabela de usuários.
  """
  
  alias Deeper_Hub.Core.Data.DBConnection.Facade, as: DB
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Cria a tabela de usuários.
  """
  def up do
    Logger.info("Criando tabela de usuários", %{module: __MODULE__})
    
    query = """
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      last_login TEXT,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """
    
    case DB.query(query, []) do
      {:ok, _} ->
        Logger.info("Tabela de usuários criada com sucesso", %{module: __MODULE__})
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de usuários", %{
          module: __MODULE__,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  @doc """
  Remove a tabela de usuários.
  """
  def down do
    Logger.info("Removendo tabela de usuários", %{module: __MODULE__})
    
    query = "DROP TABLE IF EXISTS users"
    
    case DB.query(query, []) do
      {:ok, _} ->
        Logger.info("Tabela de usuários removida com sucesso", %{module: __MODULE__})
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de usuários", %{
          module: __MODULE__,
          error: reason
        })
        
        {:error, reason}
    end
  end
end
