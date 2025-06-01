# Migração gerada com ID único: V1748745504159 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateExampleScoresSummaryTable do
  # Migração gerada com ID único: V1748745504159 em 2025-05-31 23:38:24
  @moduledoc """
  Migração EXEMPLO para criar uma tabela de sumário de scores.
  O nome real da tabela viria de sys_objects_score.table_main.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @table_name "example_scores_summary" # Este nome seria dinâmico

  @doc """
  Executa a migração para criar a tabela de exemplo.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela de exemplo de sumário de scores: #{@table_name}...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS #{@table_name} (
      -- No UNA, bx_persons_scores tem: id (PK), object_id (UNIQUE), count_up, count_down
      object_id INTEGER PRIMARY KEY NOT NULL, -- ID do item de conteúdo que foi pontuado
      count_up INTEGER NOT NULL DEFAULT 0, -- Número total de upvotes
      count_down INTEGER NOT NULL DEFAULT 0 -- Número total de downvotes
      -- A FK para object_id dependeria do tipo de conteúdo específico.
    );
    """
    # Se object_id não for PK:
    # CREATE TABLE IF NOT EXISTS #{@table_name} (
    #   id INTEGER PRIMARY KEY AUTOINCREMENT,
    #   object_id INTEGER NOT NULL UNIQUE,
    #   count_up INTEGER NOT NULL DEFAULT 0,
    #   count_down INTEGER NOT NULL DEFAULT 0
    # );
    # CREATE INDEX IF NOT EXISTS idx_#{@table_name}_object_id ON #{@table_name}(object_id);


    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela #{@table_name} criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela #{@table_name}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela de exemplo.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela #{@table_name}...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS #{@table_name};"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela #{@table_name} removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela #{@table_name}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end