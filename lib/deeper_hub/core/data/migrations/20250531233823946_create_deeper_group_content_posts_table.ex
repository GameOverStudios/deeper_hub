# Migração gerada com ID único: V1748745503945 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperGroupContentPostsTable do
  # Migração gerada com ID único: V1748745503945 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_group_content_posts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_group_content_posts.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_group_content_posts...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_group_content_posts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL,
      profile_id INTEGER NOT NULL,
      parent_post_id INTEGER,
      body TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (group_id) REFERENCES deeper_groups(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (parent_post_id) REFERENCES deeper_group_content_posts(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dgcp_group_id_created_at ON deeper_group_content_posts(group_id, created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_dgcp_profile_id ON deeper_group_content_posts(profile_id);
    CREATE INDEX IF NOT EXISTS idx_dgcp_parent_post_id ON deeper_group_content_posts(parent_post_id);
    """

    # Repo.execute("PRAGMA foreign_keys = ON;") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_group_content_posts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_group_content_posts: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_group_content_posts.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_group_content_posts...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_group_content_posts;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_group_content_posts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_group_content_posts: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
