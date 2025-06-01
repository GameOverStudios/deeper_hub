# Migração gerada com ID único: V1748745503905 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperEventsToCategoriesTable do
  # Migração gerada com ID único: V1748745503905 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela de junção deeper_events_to_categories.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_events_to_categories.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela de junção deeper_events_to_categories...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_events_to_categories (
      event_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      PRIMARY KEY (event_id, category_id),
      FOREIGN KEY (event_id) REFERENCES deeper_events(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES deeper_event_categories(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_detc_category_id_event_id ON deeper_events_to_categories(category_id, event_id);
    """

    # Repo.execute("PRAGMA foreign_keys = ON;") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de junção deeper_events_to_categories criada com sucesso.",
          module: __MODULE__
        )

        :ok

      {:error, reason} ->
        Logger.error(
          "Falha ao criar tabela de junção deeper_events_to_categories: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela de junção deeper_events_to_categories.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela de junção deeper_events_to_categories...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_events_to_categories;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de junção deeper_events_to_categories removida com sucesso.",
          module: __MODULE__
        )

        :ok

      {:error, reason} ->
        Logger.error(
          "Falha ao remover tabela de junção deeper_events_to_categories: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
