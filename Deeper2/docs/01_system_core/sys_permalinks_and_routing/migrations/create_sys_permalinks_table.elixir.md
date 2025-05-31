# Migração Elixir: Criar Tabela `sys_permalinks`

Este módulo de migração Elixir é responsável por criar a tabela `sys_permalinks` no banco de dados SQLite. Esta tabela armazena mapeamentos de URLs \"padrão\" (com query parameters) para URLs \"amigáveis\" (permalinks).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_permalinks_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysPermalinksTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_permalinks.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_permalinks.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_permalinks...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_permalinks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      standard TEXT NOT NULL,
      permalink TEXT NOT NULL,
      \"check\" TEXT NOT NULL,
      compare_by_prefix INTEGER NOT NULL DEFAULT 0
    );

    -- O índice UNIQUE original do UNA (standard(80), permalink(80), \"check\"(30))
    -- não é diretamente traduzível com prefixos para SQLite.
    -- Criar um UNIQUE nas colunas completas ou índices separados.
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_permalinks_std_perm_check ON sys_permalinks(standard, permalink, \"check\");
    CREATE INDEX IF NOT EXISTS idx_sys_permalinks_permalink ON sys_permalinks(permalink);
    CREATE INDEX IF NOT EXISTS idx_sys_permalinks_standard ON sys_permalinks(standard);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_permalinks criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_permalinks: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_permalinks.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_permalinks...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_permalinks;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_permalinks removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_permalinks: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11) UNSIGNED AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `standard`, `permalink`, `check`: `VARCHAR` (MySQL) -> `TEXT` (SQLite). A coluna `\"check\"` está entre aspas.
*   `compare_by_prefix`: `TINYINT(4)` (MySQL) -> `INTEGER` (SQLite).
*   **Índices:** O índice `UNIQUE KEY check (standard(80),permalink(80),check(30))` do MySQL, que usa prefixos de comprimento, foi adaptado. No SQLite, um índice `UNIQUE` é criado nas colunas completas (`standard`, `permalink`, `\"check\"`). Índices individuais em `permalink` e `standard` também são adicionados para otimizar buscas.