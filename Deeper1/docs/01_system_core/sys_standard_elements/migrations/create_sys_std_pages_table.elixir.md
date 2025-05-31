# Migração Elixir: Criar Tabela `sys_std_pages`

Este módulo de migração Elixir cria a tabela `sys_std_pages` no SQLite, que define as páginas padrão do sistema UNA (frequentemente usadas no painel de administração \"Studio\" ou para páginas de sistema).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_std_pages_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysStdPagesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_std_pages.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_std_pages...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_std_pages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      \"index\" INTEGER NOT NULL DEFAULT 0, -- Ordem de exibição ou agrupamento
      name TEXT NOT NULL UNIQUE, -- Nome programático da página padrão
      header TEXT NOT NULL DEFAULT '', -- Chave de tradução para o cabeçalho da página
      caption TEXT NOT NULL DEFAULT '', -- Chave de tradução para a legenda/título
      icon TEXT NOT NULL DEFAULT '' -- Classe de ícone
    );
    CREATE INDEX IF NOT EXISTS idx_sys_std_pages_name ON sys_std_pages(name);
    CREATE INDEX IF NOT EXISTS idx_sys_std_pages_index ON sys_std_pages(\"index\");
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_std_pages...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_std_pages;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```