# Migração Elixir: Criar Tabela `sys_pages_blocks_data` (Opcional)

Este módulo de migração Elixir é responsável por criar a tabela `sys_pages_blocks_data` no banco de dados SQLite. Esta tabela permite que dados de blocos específicos (`sys_pages_blocks`) sejam sobrescritos quando o bloco é exibido no contexto de um item de conteúdo particular. Seu uso é menos comum e pode ser considerado opcional para uma implementação inicial.

**Dependências:** Esta tabela possui uma chave estrangeira para `sys_pages_blocks`.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_pages_blocks_data_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysPagesBlocksDataTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_pages_blocks_data.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_pages_blocks_data.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_pages_blocks_data (opcional)...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_pages_blocks_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      block_id INTEGER NOT NULL, -- FK para sys_pages_blocks.id
      content_id INTEGER NOT NULL, -- ID do conteúdo ao qual este override se aplica
      content_module TEXT NOT NULL, -- Módulo do conteúdo
      data TEXT NOT NULL, -- Dados de override, geralmente JSON
      FOREIGN KEY (block_id) REFERENCES sys_pages_blocks(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_pages_blocks_data_block_content ON sys_pages_blocks_data(block_id, content_id, content_module);
    CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_data_content_id_module ON sys_pages_blocks_data(content_id, content_module);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_pages_blocks_data criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_pages_blocks_data: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_pages_blocks_data.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_pages_blocks_data...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_pages_blocks_data;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_pages_blocks_data removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_pages_blocks_data: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`, `block_id`, `content_id`: `INT(11)` (MySQL) -> `INTEGER` (SQLite). `id` é `PRIMARY KEY AUTOINCREMENT`.
*   `content_module`, `data`: `VARCHAR` ou `TEXT` (MySQL) -> `TEXT` (SQLite). `data` geralmente armazena JSON.
*   **Chave Estrangeira:** `block_id` para `sys_pages_blocks.id`.
*   **Índice Único:** `uidx_sys_pages_blocks_data_block_content` (originalmente `UNIQUE KEY block (block_id, content_id, content_module)`) garante a unicidade do override.