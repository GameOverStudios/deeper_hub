defmodule DeeperHub.Core.Data.Migrations.BxReputationProfilesLevels do
  @moduledoc """
  Migration para criar e remover a tabela bx_reputation_profiles_levels.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reputation_profiles_levels.
  """
  def up do
    Logger.info("Criando tabela de bx_reputation_profiles_levels...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_reputation_profiles_levels (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL DEFAULT 0,
    level_id INTEGER NOT NULL DEFAULT 0,
    date INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_profiles_levels criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_reputation_profiles_levels: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reputation_profiles_levels: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reputation_profiles_levels.
  """
  def down do
    Logger.info("Removendo tabela de bx_reputation_profiles_levels...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reputation_profiles_levels
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reputation_profiles_levels removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_reputation_profiles_levels: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reputation_profiles_levels: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
