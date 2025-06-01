# Migração Elixir: Criar Tabela `sys_objects_storage`

Este módulo de migração Elixir é responsável por criar a tabela `sys_objects_storage` no banco de dados SQLite. Esta tabela define os diferentes \"motores\" ou locais onde os arquivos podem ser armazenados (ex: sistema de arquivos local, S3).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_storage_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsStorageTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_storage.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_objects_storage.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_storage...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_storage (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE,
      engine TEXT NOT NULL,
      params TEXT,
      token_life INTEGER NOT NULL DEFAULT 3600,
      levels INTEGER NOT NULL DEFAULT 0,
      table_files TEXT NOT NULL,
      quota_size INTEGER NOT NULL DEFAULT 0,
      current_size INTEGER NOT NULL DEFAULT 0,
      quota_number INTEGER NOT NULL DEFAULT 0,
      current_number INTEGER NOT NULL DEFAULT 0,
      max_file_size INTEGER NOT NULL DEFAULT 0,
      ts INTEGER NOT NULL
    );
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_storage criada com sucesso.\", module: __MODULE__)
        # Opcional: Inserir um storage padrão 'local'
        insert_default_storage()
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_storage: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  defp insert_default_storage do
    Logger.info(\"Inserindo storage local padrão...\", module: __MODULE__)
    # Usar placeholders para segurança, mesmo para valores fixos, é uma boa prática.
    # Ou construir a query com valores interpolados se forem realmente fixos e seguros.
    # Aqui, para simplificar, vou usar interpolação, mas para dados dinâmicos, use placeholders.
    # O timestamp pode ser o atual.
    current_timestamp = DateTime.to_unix(DateTime.utc_now())
    params_json = ~s({\"path_prefix\": \"/srv/uploads/deeper_files\", \"base_url\": \"/uploads/deeper_files\"})

    sql_insert = \"\"\"
    INSERT INTO sys_objects_storage (object, engine, params, table_files, ts)
    VALUES (?, ?, ?, ?, ?);
    \"\"\"
    values = [\"deeper_local_files\", \"Local\", params_json, \"deeper_files\", current_timestamp]

    case Repo.execute(sql_insert, values) do
      {:ok, _} ->
        Logger.info(\"Storage local padrão 'deeper_local_files' inserido.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.warn(\"Falha ao inserir storage local padrão: #{inspect(reason)}. Isso pode ser ok se já existir.\", module: __MODULE__)
        # Não retornar erro aqui para não falhar a migração se o storage já existir
        # Idealmente, verificar antes de inserir ou usar INSERT OR IGNORE/REPLACE.
        # SQLite: INSERT OR IGNORE INTO sys_objects_storage (...) VALUES (...);
        # Para este exemplo, vamos assumir que uma falha aqui é recuperável ou esperada se executado múltiplas vezes.
        :ok # ou {:error, reason} se for crítico
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_objects_storage.
  \"\"\"
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

*   A coluna `object` é `UNIQUE` para garantir que cada definição de storage tenha um nome exclusivo.
*   `params` armazena configurações específicas do engine como JSON.
*   `table_files` indica qual tabela de metadados de arquivos (como `deeper_files`) usará este storage.
*   A função `insert_default_storage/0` é um exemplo de como popular a tabela com um storage local padrão após a criação. É importante lidar com a possibilidade de o registro já existir se a migração for executada mais de uma vez ou se o `down` não remover tudo. `INSERT OR IGNORE` do SQLite seria útil aqui para evitar erros em re-execuções.