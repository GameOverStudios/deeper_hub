# Migração gerada com ID único: V1748745504127 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateGenericReactionsSummaryTable do
  # Migração gerada com ID único: V1748745504127 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela genérica de sumário de reações.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    # Ou o nome que será usado
    table_name = "generic_reactions_summary"
    Logger.info("Criando tabela #{table_name}...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS #{table_name} (
      object_id INTEGER NOT NULL,
      reaction_type TEXT NOT NULL, -- 'like', 'love', etc.
      count INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (object_id, reaction_type)
      -- FOREIGN KEY (object_id) REFERENCES some_content_table(id) ON DELETE CASCADE -- Deve ser definido pelo módulo de conteúdo
    );
    CREATE INDEX IF NOT EXISTS idx_#{table_name}_object_id ON #{table_name}(object_id);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela #{table_name} criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela #{table_name}: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    table_name = "generic_reactions_summary"
    Logger.info("Removendo tabela #{table_name}...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS #{table_name};"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela #{table_name} removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela #{table_name}: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
