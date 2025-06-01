# Migração gerada com ID único: V1748745503970 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperPollOptionsTable do
  # Migração gerada com ID único: V1748745503970 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_poll_options.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_poll_options.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_poll_options...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_poll_options (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      poll_id INTEGER NOT NULL,
      option_text TEXT NOT NULL,
      order_index INTEGER NOT NULL DEFAULT 0,
      votes_count INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (poll_id) REFERENCES deeper_polls(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dpo_poll_id_order_index ON deeper_poll_options(poll_id, order_index);
    """

    # Repo.execute("PRAGMA foreign_keys = ON;") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_poll_options criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_poll_options: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_poll_options.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_poll_options...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_poll_options;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_poll_options removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_poll_options: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end