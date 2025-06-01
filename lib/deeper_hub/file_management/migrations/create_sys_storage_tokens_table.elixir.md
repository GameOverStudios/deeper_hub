# Migração Elixir: Criar Tabela `sys_storage_tokens`

Este módulo de migração Elixir é responsável por criar a tabela `sys_storage_tokens` no banco de dados SQLite. Esta tabela é usada para gerenciar tokens de acesso de curta duração para arquivos, especialmente útil para controlar o acesso a arquivos privados.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_storage_tokens_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStorageTokensTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_storage_tokens.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_storage_tokens.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_storage_tokens...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_storage_tokens (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      file_id INTEGER NOT NULL,
      storage_object TEXT NOT NULL,
      hash TEXT NOT NULL UNIQUE,
      created INTEGER NOT NULL,
      FOREIGN KEY (file_id) REFERENCES deeper_files(id) ON DELETE CASCADE,
      FOREIGN KEY (storage_object) REFERENCES sys_objects_storage(object) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_storage_tokens_hash ON sys_storage_tokens(hash);
    CREATE INDEX IF NOT EXISTS idx_sys_storage_tokens_created ON sys_storage_tokens(created);
    -- Opcional: um índice em file_id pode ser útil se você frequentemente busca tokens por file_id
    CREATE INDEX IF NOT EXISTS idx_sys_storage_tokens_file_id ON sys_storage_tokens(file_id);
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_storage_tokens criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_storage_tokens: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_storage_tokens.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_storage_tokens...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_storage_tokens;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_storage_tokens removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_storage_tokens: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   A tabela `sys_storage_tokens` liga um token (`hash`) a um arquivo específico (`file_id` referenciando `deeper_files.id`) e ao seu `storage_object`.
*   `FOREIGN KEY (file_id) REFERENCES deeper_files(id) ON DELETE CASCADE`: Se um arquivo for excluído da tabela `deeper_files`, todos os tokens associados a ele serão automaticamente removidos.
*   `FOREIGN KEY (storage_object) REFERENCES sys_objects_storage(object) ON DELETE CASCADE`: Se um objeto de storage for excluído, todos os tokens associados a arquivos nesse storage serão removidos. Isso é consistente se o `deeper_files` também usar `CASCADE` para `storage_object`, ou pode levar a tokens órfãos se `deeper_files` usar `RESTRICT`. A consistência nas ações `ON DELETE` é importante. Se `deeper_files` usa `RESTRICT` para `storage_object`, então `sys_storage_tokens` provavelmente deveria usar `RESTRICT` também ou depender da remoção via `file_id` cascateada. Para este exemplo, `CASCADE` é usado para simplificar, assumindo que a remoção de um storage implica na remoção de seus tokens.
*   O `hash` do token deve ser `UNIQUE` para evitar colisões.
*   `created` é um timestamp Unix para rastrear quando o token foi gerado, permitindo a implementação de lógica de expiração (comparando com `token_life` da tabela `sys_objects_storage`).