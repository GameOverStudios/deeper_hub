# Migração Elixir: Criar Tabela `sys_std_widgets`

Este módulo de migração Elixir cria a tabela `sys_std_widgets` no SQLite, que define os widgets padrão que podem ser exibidos em páginas padrão ou dashboards.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_std_widgets_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStdWidgetsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_std_widgets.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_std_widgets...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_std_widgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      page_id TEXT NOT NULL DEFAULT '', -- No UNA, isto pode ser o 'name' da sys_std_pages ou um ID/nome de um dashboard dinâmico
      module TEXT NOT NULL DEFAULT '', -- Módulo que fornece o widget
      type TEXT NOT NULL DEFAULT '', -- Tipo de widget (ex: 'chart', 'list', 'custom_html')
      url TEXT NOT NULL DEFAULT '', -- URL para buscar dados do widget ou link do widget
      click TEXT NOT NULL DEFAULT '', -- Ação JS onclick original
      icon TEXT NOT NULL DEFAULT '', -- Classe de ícone
      caption TEXT NOT NULL DEFAULT '', -- Chave de tradução para o título do widget
      cnt_notices TEXT NOT NULL DEFAULT '', -- Lógica PHP/Serviço para buscar contagem de notices
      cnt_actions TEXT NOT NULL DEFAULT '', -- Lógica PHP/Serviço para buscar contagem de ações
      featured INTEGER NOT NULL DEFAULT 0 -- 0 ou 1
    );
    -- O schema original tem um UNIQUE KEY em (id, page_id(187)), o que é incomum para um PK 'id'.
    -- Vamos manter o PK 'id' e talvez adicionar um índice em 'page_id'.
    CREATE INDEX IF NOT EXISTS idx_sys_std_widgets_page_id ON sys_std_widgets(page_id);
    CREATE INDEX IF NOT EXISTS idx_sys_std_widgets_module_type ON sys_std_widgets(module, type);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_std_widgets...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_std_widgets;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```