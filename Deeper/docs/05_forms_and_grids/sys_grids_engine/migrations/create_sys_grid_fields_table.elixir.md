# Migração Elixir: Criar Tabela `sys_grid_fields`

Este módulo de migração Elixir cria a tabela `sys_grid_fields` no SQLite, que define as colunas a serem exibidas em cada grid.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_grid_fields_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysGridFieldsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_grid_fields.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_grid_fields...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_grid_fields (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL, -- FK para sys_objects_grid.object
      name TEXT NOT NULL, -- Nome da coluna (deve corresponder a uma coluna na 'source' query da grid)
      title TEXT NOT NULL, -- Chave de tradução para o cabeçalho da coluna
      width TEXT NOT NULL DEFAULT 'auto', -- Ex: '10%', '100px', 'auto'
      translatable INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se o valor da célula é uma chave de tradução)
      chars_limit INTEGER NOT NULL DEFAULT 0, -- Limite de caracteres para exibição (0 = sem limite)
      params TEXT NOT NULL DEFAULT '', -- Originalmente para callbacks PHP, pode ser JSON para formatadores na API Deeper
      hidden_on TEXT NOT NULL DEFAULT '', -- Ex: 'mobile', 'desktop', ou JSON de condições
      \"order\" INTEGER NOT NULL DEFAULT 0,
      UNIQUE(object, name)
      -- FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON DELETE CASCADE -- Opcional
    );
    CREATE INDEX IF NOT EXISTS idx_sys_grid_fields_object_order ON sys_grid_fields(object, \"order\");
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_grid_fields...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_grid_fields;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```