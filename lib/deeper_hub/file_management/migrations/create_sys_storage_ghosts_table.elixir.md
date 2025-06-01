# Migração Elixir: Criar Tabela `sys_storage_ghosts`

Este módulo de migração Elixir cria a tabela `sys_storage_ghosts` no banco de dados SQLite. Esta tabela é usada no UNA para rastrear \"arquivos fantasmas\" - arquivos que foram carregados (ex: em um formulário), mas cujo conteúdo pai ainda não foi salvo. Isso permite a limpeza posterior de arquivos não utilizados.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_storage_ghosts_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStorageGhostsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_storage_ghosts.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_storage_ghosts...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_storage_ghosts (
      iid INTEGER PRIMARY KEY AUTOINCREMENT, -- Chave primária interna da tabela de ghosts
      id INTEGER NOT NULL, -- ID do arquivo na sua tabela de metadados (ex: sys_files.id)
      profile_id INTEGER NOT NULL, -- sys_profiles.id do uploader
      object TEXT NOT NULL, -- Nome do sys_objects_storage ao qual o arquivo pertence
      content_id INTEGER NOT NULL, -- ID do conteúdo ao qual o arquivo está (ou estaria) associado (pode ser 0 se ainda não definido)
      created INTEGER NOT NULL, -- Unix Timestamp de quando o ghost foi criado
      \"order\" INTEGER NOT NULL DEFAULT 0 -- Ordem, se múltiplos ghosts para o mesmo content_id
    );
    -- O schema original do UNA tem UNIQUE KEY (id, object), o que significa que um arquivo (id)
    -- só pode ser um ghost para um storage object específico uma vez.
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_storage_ghosts_id_object ON sys_storage_ghosts(id, object);
    CREATE INDEX IF NOT EXISTS idx_sys_storage_ghosts_created ON sys_storage_ghosts(created);
    CREATE INDEX IF NOT EXISTS idx_sys_storage_ghosts_profile_object_content ON sys_storage_ghosts(profile_id, object, content_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_storage_ghosts criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_storage_ghosts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_storage_ghosts...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_storage_ghosts;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_storage_ghosts removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_storage_ghosts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `id`: Refere-se ao ID do arquivo na tabela de metadados especificada por `object` (ex: `sys_files.id`).
*   `object`: O nome do `sys_objects_storage` onde o arquivo foi carregado.
*   `content_id`: Pode ser 0 ou um ID temporário se o conteúdo principal ainda não foi criado. Após o conteúdo ser salvo, o registro fantasma correspondente é geralmente removido.
*   Um job de limpeza no UNA periodicamente remove ghosts antigos (ex: com mais de 24 horas) e seus arquivos físicos associados se eles não foram convertidos em arquivos permanentes.