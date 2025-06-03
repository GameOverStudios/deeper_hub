defmodule DeeperHub.Core.Data.Migrations.BxReputationProfiles do
  @moduledoc """
  Migration para criar e remover a tabela bx_reputation_profiles.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reputation_profiles.
  """
  def up do
    Logger.info("Criando tabela de bx_reputation_profiles...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_reputation_profiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
    points INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_profiles criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_reputation_profiles: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reputation_profiles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reputation_profiles.
  """
  def down do
    Logger.info("Removendo tabela de bx_reputation_profiles...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reputation_profiles
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_profiles removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_reputation_profiles: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reputation_profiles: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
