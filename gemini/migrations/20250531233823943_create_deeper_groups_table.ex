# Migração gerada com ID único: V1748745503942 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperGroupsTable do
  # Migração gerada com ID único: V1748745503942 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_groups.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_groups.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_groups...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_groups (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      slug TEXT NOT NULL UNIQUE,
      description TEXT,
      rules TEXT,
      avatar_file_id INTEGER,
      cover_file_id INTEGER,
      privacy_level TEXT NOT NULL DEFAULT 'public' CHECK(privacy_level IN ('public', 'private', 'secret')),
      allow_member_invites INTEGER NOT NULL DEFAULT 1,
      join_approval_mode TEXT NOT NULL DEFAULT 'open' CHECK(join_approval_mode IN ('open', 'approval', 'invite_only')),
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'suspended_by_admin', 'deleted_by_owner')),
      members_count INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE RESTRICT,
      FOREIGN KEY (avatar_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL,
      FOREIGN KEY (cover_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_groups_profile_id ON deeper_groups(profile_id);
    CREATE INDEX IF NOT EXISTS idx_deeper_groups_slug ON deeper_groups(slug);
    CREATE INDEX IF NOT EXISTS idx_deeper_groups_privacy_level ON deeper_groups(privacy_level);
    CREATE INDEX IF NOT EXISTS idx_deeper_groups_status ON deeper_groups(status);
    """

    # Repo.execute("PRAGMA foreign_keys = ON;") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_groups criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_groups: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_groups.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_groups...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_groups;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_groups removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_groups: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
