# Migração Elixir: Criar Tabela `sys_std_widgets`

Este módulo de migração Elixir é responsável por criar a tabela `sys_std_widgets` no banco de dados SQLite. Esta tabela define widgets padrão que podem ser utilizados nas páginas padrão do sistema (especialmente no Studio do UNA).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_std_widgets_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStdWidgetsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_std_widgets.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_std_widgets.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_std_widgets...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_std_widgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      page_id TEXT NOT NULL, -- Pode referenciar sys_std_pages.name
      module TEXT,
      type TEXT,
      url TEXT,
      click TEXT,
      icon TEXT,
      caption TEXT,
      cnt_notices TEXT, -- Lógica para contagem de notificações (geralmente string de service call no UNA)
      cnt_actions TEXT, -- Lógica para contagem de ações (geralmente string de service call no UNA)
      featured INTEGER NOT NULL DEFAULT 0 -- 0 ou 1
    );

    CREATE INDEX IF NOT EXISTS idx_sys_std_widgets_page_id ON sys_std_widgets(page_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_std_widgets criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_std_widgets: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_std_widgets.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_std_widgets...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_std_widgets;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_std_widgets removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_std_widgets: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11) UNSIGNED AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `page_id`, `module`, `type`, `url`, `icon`, `caption`: `VARCHAR` (MySQL) -> `TEXT` (SQLite).
*   `click`, `cnt_notices`, `cnt_actions`: `TEXT` (MySQL) -> `TEXT` (SQLite). No UNA, `cnt_notices` e `cnt_actions` frequentemente contêm chamadas de serviço serializadas; para a API \"Deeper\", seu uso direto pode ser limitado.
*   `featured`: `TINYINT(4) UNSIGNED` (MySQL) -> `INTEGER` (SQLite) (0 ou 1).