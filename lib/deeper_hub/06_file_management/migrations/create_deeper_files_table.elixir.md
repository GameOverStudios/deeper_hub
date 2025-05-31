# Migração Elixir: Criar Tabela `deeper_files`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_files` no banco de dados SQLite. Esta é a tabela principal para armazenar metadados sobre todos os arquivos enviados para o sistema \"Deeper\".

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_files_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperFilesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_files.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_files.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_files...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_files (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      storage_object TEXT NOT NULL,
      remote_id TEXT NOT NULL,
      path TEXT,
      file_name TEXT NOT NULL,
      mime_type TEXT NOT NULL,
      ext TEXT NOT NULL,
      size INTEGER NOT NULL,
      added INTEGER NOT NULL,
      modified INTEGER NOT NULL,
      is_private INTEGER NOT NULL DEFAULT 0,
      img_width INTEGER,
      img_height INTEGER,
      meta TEXT,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
      FOREIGN KEY (storage_object) REFERENCES sys_objects_storage(object) ON DELETE RESTRICT -- Ou CASCADE se preferir deletar arquivos quando o storage é removido
    );

    CREATE INDEX IF NOT EXISTS idx_deeper_files_profile_id ON deeper_files(profile_id);
    -- Criar um índice único para garantir que o remote_id seja único dentro de um storage_object
    CREATE UNIQUE INDEX IF NOT EXISTS idx_deeper_files_storage_remote_id ON deeper_files(storage_object, remote_id);
    CREATE INDEX IF NOT EXISTS idx_deeper_files_mime_type ON deeper_files(mime_type);
    CREATE INDEX IF NOT EXISTS idx_deeper_files_added ON deeper_files(added);
    CREATE INDEX IF NOT EXISTS idx_deeper_files_is_private ON deeper_files(is_private);
    \"\"\"

    # Habilitar chaves estrangeiras para esta sessão de conexão se não estiver globalmente habilitado
    # Esta é uma boa prática ao trabalhar com FKs no SQLite via código.
    # No entanto, o módulo Repo pode já lidar com isso.
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_files criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_files: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_files.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_files...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_files;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_files removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_files: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   A tabela `deeper_files` possui chaves estrangeiras para `sys_profiles` (para identificar o uploader) e `sys_objects_storage` (para identificar onde o arquivo está armazenado).
    *   `FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL`: Se um perfil de usuário for excluído, o `profile_id` nos arquivos que ele enviou será definido como `NULL`. Isso mantém os arquivos, mas desassocia o uploader. Alternativamente, `ON DELETE CASCADE` removeria os arquivos, o que pode ou não ser desejado.
    *   `FOREIGN KEY (storage_object) REFERENCES sys_objects_storage(object) ON DELETE RESTRICT`: Impede a exclusão de um `sys_objects_storage` se houver arquivos ainda referenciando-o. `ON DELETE CASCADE` poderia ser usado se a intenção fosse deletar todos os arquivos quando um storage é removido, mas isso é geralmente uma operação perigosa.
*   Um índice `UNIQUE` (`idx_deeper_files_storage_remote_id`) é criado em `(storage_object, remote_id)` para garantir que cada arquivo tenha um identificador (`remote_id`) único dentro de um determinado sistema de armazenamento (`storage_object`).
*   O comentário sobre `PRAGMA foreign_keys = ON;` é importante. Se o seu módulo `Deeper.Core.Data.Repo` não habilitar chaves estrangeiras por padrão para cada conexão, você pode precisar executá-lo antes de DDLs que definem ou dependem de FKs, ou garantir que esteja configurado no nível da conexão do pool.
*   Campos como `img_width`, `img_height`, e `meta` (JSON) oferecem flexibilidade para armazenar informações adicionais específicas do arquivo.