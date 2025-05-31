# Migração Elixir: Criar Tabela `sys_pages_types`

Este módulo de migração Elixir é responsável por criar a tabela `sys_pages_types` no banco de dados SQLite. Esta tabela define diferentes \"tipos\" de páginas (ex: padrão, sistema, perfil), que podem ter templates base ou comportamentos distintos no sistema UNA.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_pages_types_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysPagesTypesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_pages_types.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_pages_types.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_pages_types...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_pages_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      template TEXT NOT NULL, -- Nome do arquivo de template HTML base
      \"order\" INTEGER NOT NULL
    );
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_pages_types criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_pages_types: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_pages_types.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_pages_types...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_pages_types;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_pages_types removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_pages_types: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11)` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `title`, `template`: `VARCHAR(255)` (MySQL) -> `TEXT` (SQLite).
*   `order`: `INT(11)` (MySQL) -> `INTEGER` (SQLite). Colocado entre aspas (`\"order\"`).