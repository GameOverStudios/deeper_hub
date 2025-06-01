# Migração Elixir: Criar Tabela `deeper_photo_albums`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_photo_albums` no banco de dados SQLite. Esta tabela armazena as informações principais sobre os álbuns de fotos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_photo_albums_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperPhotoAlbumsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_photo_albums.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_photo_albums.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_photo_albums...\", module: __MODULE__)

    # A FK para cover_photo_id (referenciando deeper_album_photos)
    # será definida na migração de deeper_album_photos via ALTER TABLE ou
    # a integridade é gerenciada pela aplicação, pois deeper_album_photos não existe ainda.
    # Ou, criamos a coluna cover_photo_id aqui e adicionamos a constraint FK depois.
    # Para SQLite, é mais fácil criar a coluna e a FK ao mesmo tempo se a tabela referenciada existir.
    # Aqui, vamos definir a coluna e a FK com ON DELETE SET NULL, assumindo que a ordem de execução das migrações
    # ou a habilidade de deferir FKs (não padrão no SQLite DDL simples) lidará com isso.
    # Se deeper_album_photos não existe, a FK não pode ser validada na criação.
    # A melhor abordagem é criar a coluna aqui, e a FK constraint após a criação de deeper_album_photos,
    # ou apenas criar a coluna aqui e a aplicação lida com a integridade ou a FK é adicionada
    # na migração de `deeper_album_photos` usando `ALTER TABLE deeper_photo_albums ADD CONSTRAINT...`
    # (que é limitado no SQLite).
    #
    # Simplificação: criamos a coluna, a FK é definida, mas só será efetiva/verificada após
    # a criação da tabela referenciada e se as FKs estiverem habilitadas.

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_photo_albums (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      slug TEXT NOT NULL UNIQUE,
      description TEXT,
      cover_photo_id INTEGER, -- Será FK para deeper_album_photos.id
      privacy_level TEXT NOT NULL DEFAULT 'public' CHECK(privacy_level IN ('public', 'private_members_only', 'private_link', 'private_me_only')),
      allow_comments INTEGER NOT NULL DEFAULT 1,
      photos_count INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (cover_photo_id) REFERENCES deeper_album_photos(id) ON DELETE SET NULL -- Declarada, mas depende da existência de deeper_album_photos
    );

    CREATE INDEX IF NOT EXISTS idx_dpa_profile_id ON deeper_photo_albums(profile_id);
    CREATE INDEX IF NOT EXISTS idx_dpa_slug ON deeper_photo_albums(slug);
    CREATE INDEX IF NOT EXISTS idx_dpa_privacy_level ON deeper_photo_albums(privacy_level);
    \"\"\"
    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_photo_albums criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_photo_albums: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_photo_albums.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_photo_albums...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_photo_albums;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_photo_albums removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_photo_albums: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Depende de `sys_profiles`.
*   A chave estrangeira `cover_photo_id` para `deeper_album_photos(id)` é declarada. A sua aplicação (enforcement) pelo SQLite no momento da criação desta tabela depende da ordem das migrações. Se `deeper_album_photos` for criada depois, a constraint só se tornará \"viva\" quando essa tabela existir e `PRAGMA foreign_keys = ON` estiver ativo.