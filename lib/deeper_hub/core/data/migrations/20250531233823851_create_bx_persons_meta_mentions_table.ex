# Migração gerada com ID único: V1748745503851 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateBxPersonsMetaMentionsTable do
  # Migração gerada com ID único: V1748745503851 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela bx_persons_meta_mentions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_persons_meta_mentions.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_persons_meta_mentions...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS bx_persons_meta_mentions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil/conteúdo ONDE a menção ocorre)
      profile_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil QUE FOI mencionado)
      FOREIGN KEY (object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_meta_mentions_object_id ON bx_persons_meta_mentions(object_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_meta_mentions_profile_id ON bx_persons_meta_mentions(profile_id);
    -- Para evitar múltiplas menções idênticas do mesmo profile no mesmo objeto:
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_persons_meta_mentions_object_profile ON bx_persons_meta_mentions(object_id, profile_id);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_meta_mentions criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_persons_meta_mentions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_persons_meta_mentions.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_persons_meta_mentions...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS bx_persons_meta_mentions;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_meta_mentions removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_persons_meta_mentions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end