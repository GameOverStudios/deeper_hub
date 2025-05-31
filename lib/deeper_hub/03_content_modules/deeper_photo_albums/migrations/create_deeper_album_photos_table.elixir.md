# Migração Elixir: Criar Tabela `deeper_album_photos`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_album_photos` no banco de dados SQLite. Esta tabela armazena as referências às fotos individuais dentro de cada álbum, juntamente com seus metadados específicos como legenda e ordem.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_album_photos_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperAlbumPhotosTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_album_photos.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_album_photos.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_album_photos...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_album_photos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      album_id INTEGER NOT NULL,
      file_id INTEGER NOT NULL UNIQUE, -- UNIQUE aqui assume que um arquivo não é reutilizado como \"foto de álbum\" diferente
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
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_album_photos criada com sucesso.\", module: __MODULE__)
        # Neste ponto, a tabela deeper_photo_albums e deeper_album_photos existem.
        # Se a FK de deeper_photo_albums.cover_photo_id para deeper_album_photos.id
        # não foi criada com sucesso devido à ordem, esta seria uma oportunidade para
        # tentar adicioná-la via ALTER TABLE, embora seja complexo no SQLite.
        # Ex: (mas isto não funciona para adicionar FKs no SQLite diretamente)
        # sql_alter = \"ALTER TABLE deeper_photo_albums ADD CONSTRAINT fk_cover_photo FOREIGN KEY (cover_photo_id) REFERENCES deeper_album_photos(id) ON DELETE SET NULL;\"
        # Repo.execute(sql_alter)
        # A melhor prática é garantir que a integridade seja mantida pela aplicação ou
        # que as tabelas sejam criadas em uma ordem que permita a definição de FKs,
        # ou usar FKs deferíveis se suportado e necessário.
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_album_photos: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_album_photos.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_album_photos...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_album_photos;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_album_photos removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_album_photos: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela depende da existência de `deeper_photo_albums` (para `album_id`), `deeper_files` (para `file_id`), e `sys_profiles` (para `profile_id`).
*   A constraint `UNIQUE` em `file_id` implica que um arquivo específico (`deeper_files.id`) só pode ser associado como uma \"foto de álbum\" uma única vez em todo o sistema. Se o mesmo arquivo pudesse ser adicionado a múltiplos álbuns ou múltiplas vezes ao mesmo álbum (como entradas distintas), esta constraint `UNIQUE` deveria ser removida e a unicidade gerenciada de outra forma (ex: `UNIQUE(album_id, file_id)` se um arquivo só pode estar uma vez por álbum). A abordagem atual é mais simples e trata cada entrada `deeper_album_photos` como uma instância única de uma foto em um contexto de álbum.
*   `ON DELETE CASCADE` para `album_id` e `file_id` garante que se o álbum pai ou o arquivo original forem excluídos, esta entrada de \"foto do álbum\" também será.
*   O índice `idx_dap_album_id_order_index` é crucial para listar as fotos de um álbum na ordem correta.