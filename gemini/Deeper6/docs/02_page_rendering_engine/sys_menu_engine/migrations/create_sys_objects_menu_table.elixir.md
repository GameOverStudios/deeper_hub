# Migração Elixir: Criar Tabela `sys_objects_menu`

Este módulo de migração Elixir é responsável por criar a tabela `sys_objects_menu` no banco de dados SQLite. Esta tabela define os \"objetos de menu\" concretos usados no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_menu_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsMenuTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_menu.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_objects_menu...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_menu (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      set_name TEXT NOT NULL,
      module TEXT NOT NULL,
      template_id INTEGER NOT NULL,
      deletable INTEGER NOT NULL DEFAULT 1,
      active INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (set_name) REFERENCES sys_menu_sets(set_name) ON UPDATE CASCADE ON DELETE RESTRICT,
      FOREIGN KEY (template_id) REFERENCES sys_menu_templates(id) ON UPDATE CASCADE ON DELETE RESTRICT
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_set_name ON sys_objects_menu(set_name);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_menu_module ON sys_objects_menu(module);
    \"\"\"
    # Habilitar chaves estrangeiras para esta sessão de conexão, se o Repo não fizer isso globalmente
    # Repo.execute(\"PRAGMA foreign_keys = ON;\") # Pode ser necessário antes do CREATE TABLE

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_menu criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_menu: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  def down do
    Logger.info(\"Removendo tabela sys_objects_menu...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_menu;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_menu removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_objects_menu: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

**Nota sobre Chaves Estrangeiras no SQLite:**
Para que as chaves estrangeiras sejam efetivamente aplicadas no SQLite, o `PRAGMA foreign_keys = ON;` deve ser executado para cada conexão. Se o seu módulo `Deeper.Core.Data.Repo` ou a biblioteca `DBConnection` não configuram isso por padrão ao abrir conexões, pode ser necessário executá-lo antes de comandos que dependem de FKs (como este `CREATE TABLE`). Alternativamente, pode ser uma configuração global ao iniciar o pool de conexões.