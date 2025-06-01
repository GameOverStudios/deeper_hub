# Migração gerada com ID único: V1748745503952 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperAlbumPhotosTable do
  # Migração gerada com ID único: V1748745503952 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_album_photos.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_album_photos.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_album_photos...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_album_photos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      album_id INTEGER NOT NULL,
      file_id INTEGER NOT NULL UNIQUE, -- UNIQUE aqui assume que um arquivo não é reutilizado como "foto de álbum" diferente
      profile_id INTEGER NOT NULL,
      title TEXT, -- Legenda da foto
      description TEXT,
      order_index INTEGER NOT NULL DEFAULT 0,
      views_count INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (album_id) REFERENCES deeper_photo_albums(id) ON DELETE CASCADE,
      FOREIGN KEY (file_id) REFERENCES deeper_files(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL
    );

    CREATE INDEX IF NOT EXISTS idx_dap_album_id_order_index ON deeper_album_photos(album_id, order_index);
    -- O índice idx_dap_file_id é criado automaticamente pela constraint UNIQUE(file_id) no SQLite.
    -- Se não fosse UNIQUE, um índice explícito seria:
    -- CREATE INDEX IF NOT EXISTS idx_dap_file_id ON deeper_album_photos(file_id);
    CREATE INDEX IF NOT EXISTS idx_dap_profile_id ON deeper_album_photos(profile_id);
    """

    # Repo.execute("PRAGMA foreign_keys = ON;") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_album_photos criada com sucesso.", module: __MODULE__)
        # Neste ponto, a tabela deeper_photo_albums e deeper_album_photos existem.
        # Se a FK de deeper_photo_albums.cover_photo_id para deeper_album_photos.id
        # não foi criada com sucesso devido à ordem, esta seria uma oportunidade para
        # tentar adicioná-la via ALTER TABLE, embora seja complexo no SQLite.
        # Ex: (mas isto não funciona para adicionar FKs no SQLite diretamente)
        # sql_alter = "ALTER TABLE deeper_photo_albums ADD CONSTRAINT fk_cover_photo FOREIGN KEY (cover_photo_id) REFERENCES deeper_album_photos(id) ON DELETE SET NULL;"
        # Repo.execute(sql_alter)
        # A melhor prática é garantir que a integridade seja mantida pela aplicação ou
        # que as tabelas sejam criadas em uma ordem que permita a definição de FKs,
        # ou usar FKs deferíveis se suportado e necessário.
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_album_photos: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_album_photos.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_album_photos...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_album_photos;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_album_photos removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_album_photos: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end