# Migração gerada com ID único: V1748745503856 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateBxPersonsPicturesTable do
  # Migração gerada com ID único: V1748745503856 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela bx_persons_pictures.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_persons_pictures.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_persons_pictures...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS bx_persons_pictures (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL, -- FK para sys_profiles.id
      remote_id TEXT, -- ID do arquivo no storage
      path TEXT NOT NULL,
      file_name TEXT NOT NULL,
      mime_type TEXT NOT NULL,
      ext TEXT NOT NULL,
      size INTEGER NOT NULL,
      dimensions TEXT, -- Ex: '800x600'
      added INTEGER NOT NULL, -- Unix Timestamp
      modified INTEGER NOT NULL, -- Unix Timestamp
      private INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_pictures_profile_id ON bx_persons_pictures(profile_id);
    -- O UNIQUE KEY remote_id do UNA original.
    -- Se remote_id pode ser NULL ou vazio e ainda assim o resto da linha ser válida,
    -- um índice UNIQUE condicional é melhor, ou a lógica da aplicação garante a unicidade dos remote_ids não nulos.
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_persons_pictures_remote_id ON bx_persons_pictures(remote_id)
      WHERE remote_id IS NOT NULL AND remote_id != '';
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_pictures criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_persons_pictures: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_persons_pictures.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_persons_pictures...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS bx_persons_pictures;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_pictures removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_persons_pictures: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
