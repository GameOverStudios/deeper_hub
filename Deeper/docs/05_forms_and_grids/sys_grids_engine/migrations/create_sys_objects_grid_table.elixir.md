# Migração Elixir: Criar Tabela `sys_objects_grid`

Este módulo de migração Elixir cria a tabela `sys_objects_grid` no SQLite, que define as propriedades de cada grid de dados no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_grid_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsGridTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_grid.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_grid...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_grid (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE,
      source_type TEXT NOT NULL DEFAULT 'Sql' CHECK(source_type IN ('Sql', 'Array')),
      source TEXT NOT NULL, -- Query SQL ou identificador de fonte
      \"table\" TEXT NOT NULL, -- Tabela principal da query (para referência/otimizações)
      field_id TEXT NOT NULL, -- Coluna PK na 'table' ou na 'source' query
      field_order TEXT NOT NULL, -- Coluna(s) de ordenação padrão, ex: 'col1 ASC, col2 DESC'
      field_active TEXT, -- Coluna para status ativo/inativo
      order_get_field TEXT DEFAULT 'order_field', -- Parâmetro URL original para campo de ordenação
      order_get_dir TEXT DEFAULT 'order_dir', -- Parâmetro URL original para direção de ordenação
      paginate_url TEXT, -- URL de paginação original do UNA PHP
      paginate_per_page INTEGER NOT NULL DEFAULT 10,
      paginate_simple TEXT, -- Se usa paginação simples (ex: Next/Prev)
      paginate_get_start TEXT DEFAULT 'start', -- Parâmetro URL original para offset/start
      paginate_get_per_page TEXT DEFAULT 'per_page', -- Parâmetro URL original para itens por página
      filter_fields TEXT, -- CSV ou JSON de colunas filtráveis
      filter_fields_translatable TEXT, -- CSV ou JSON de colunas filtráveis que são traduzíveis
      filter_mode TEXT DEFAULT 'auto' CHECK(filter_mode IN ('like', 'fulltext', 'auto')),
      filter_get TEXT DEFAULT 'filter', -- Parâmetro URL original para string de filtro
      sorting_fields TEXT, -- CSV ou JSON de colunas ordenáveis
      -- sorting_fields_translatable TEXT, -- Omitido no dump original
      visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Máscara de bits ACL
      responsive INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      show_total_count INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      override_class_name TEXT, -- Específico do UNA PHP
      override_class_file TEXT -- Específico do UNA PHP
    );
    CREATE INDEX IF NOT EXISTS idx_sys_objects_grid_object ON sys_objects_grid(object);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_grid...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_grid;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```