# Migração Elixir: Criar Tabela `sys_menu_templates`

Este módulo de migração Elixir é responsável por criar a tabela `sys_menu_templates` no banco de dados SQLite. Esta tabela define os diferentes templates visuais que podem ser usados para renderizar menus no sistema UNA (embora sua relevância direta para a API \"Deeper\" seja menor, a estrutura é mantida).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_menu_templates_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysMenuTemplatesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_menu_templates.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_menu_templates.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_menu_templates...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_menu_templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      template TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      visible INTEGER NOT NULL DEFAULT 1 -- 0 ou 1
    );
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_menu_templates criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_menu_templates: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_menu_templates.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_menu_templates...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_menu_templates;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_menu_templates removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_menu_templates: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11)` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `template`, `title`: `VARCHAR(255)` (MySQL) -> `TEXT` (SQLite). `template` é `UNIQUE`.
*   `visible`: `TINYINT(4)` (MySQL) -> `INTEGER` (SQLite), (0 ou 1).