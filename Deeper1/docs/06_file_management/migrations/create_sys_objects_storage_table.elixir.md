# Migração Elixir: Criar Tabela `sys_objects_storage`

Este módulo de migração Elixir cria a tabela `sys_objects_storage` no banco de dados SQLite. Esta tabela é fundamental para o sistema de gerenciamento de arquivos, pois define os diferentes \"objetos de armazenamento\" (engines como Local, S3) e suas configurações.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_storage_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsStorageTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_storage.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_storage...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_storage (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE,
      engine TEXT NOT NULL, -- 'Local', 'S3', 'Wasabi', 'Cloudflare', etc.
      params TEXT, -- JSON com configurações: ex: bucket, region, key, secret para S3; path para Local
      token_life INTEGER NOT NULL DEFAULT 3600,
      cache_control INTEGER NOT NULL DEFAULT 2592000, -- Em segundos
      levels INTEGER NOT NULL DEFAULT 0, -- Para engine 'Local', profundidade de subdiretórios
      table_files TEXT NOT NULL, -- Nome da tabela SQL que armazena metadados dos arquivos
      ext_mode TEXT NOT NULL DEFAULT 'allow-deny' CHECK(ext_mode IN ('allow-deny', 'deny-allow')),
      ext_allow TEXT DEFAULT 'jpg,jpeg,gif,png,webp,pdf,doc,docx,xls,xlsx,ppt,pptx,zip,mp3,mp4,mov,avi',
      ext_deny TEXT DEFAULT 'exe,sh,php,js',
      quota_size INTEGER NOT NULL DEFAULT 0, -- Em bytes, 0 para ilimitado
      current_size INTEGER NOT NULL DEFAULT 0,
      quota_number INTEGER NOT NULL DEFAULT 0, -- Número de arquivos, 0 para ilimitado
      current_number INTEGER NOT NULL DEFAULT 0,
      max_file_size INTEGER NOT NULL DEFAULT 10485760, -- Tamanho máximo por arquivo em bytes (ex: 10MB), 0 para ilimitado
      ts INTEGER NOT NULL DEFAULT 0 -- Timestamp da última atualização de current_size/number
    );
    CREATE INDEX IF NOT EXISTS idx_sys_objects_storage_object ON sys_objects_storage(object);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_storage criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_storage: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_storage...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_storage;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_storage removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_objects_storage: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `object`: Nome único do storage object (ex: `bx_persons_pictures_storage`, `general_files_storage`).
*   `engine`: Tipo de backend de armazenamento.
*   `params`: Configurações específicas do engine, armazenadas como JSON.
*   `table_files`: Nome da tabela SQL que armazena os metadados dos arquivos para este storage object.
*   `ext_mode`, `ext_allow`, `ext_deny`: Para controle de tipos de arquivo permitidos.
*   `quota_*`, `current_*`, `max_file_size`: Para gerenciamento de cotas e limites.