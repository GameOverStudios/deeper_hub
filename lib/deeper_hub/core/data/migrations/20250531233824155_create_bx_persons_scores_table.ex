# Migração gerada com ID único: V1748745504155 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateBxPersonsScoresTable do
  # Migração gerada com ID único: V1748745504155 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela de agregação de scores bx_persons_scores.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_persons_scores.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_persons_scores...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_persons_scores (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL UNIQUE, -- FK para bx_persons_data.id
      count_up INTEGER NOT NULL DEFAULT 0,
      count_down INTEGER NOT NULL DEFAULT 0
      -- FOREIGN KEY (object_id) REFERENCES bx_persons_data(id) ON DELETE CASCADE -- Opcional
    );
    CREATE INDEX IF NOT EXISTS idx_bx_persons_scores_object_id ON bx_persons_scores(object_id);
    """
    # O schema original do UNA tem 'id' como PK e 'object_id' como UNIQUE.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_scores criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_persons_scores: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_persons_scores.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_persons_scores...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS bx_persons_scores;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_scores removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_persons_scores: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end