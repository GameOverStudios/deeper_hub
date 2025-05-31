# Migração Elixir: Criar Tabela `sys_pages_design_boxes`

Este módulo de migração Elixir cria a tabela `sys_pages_design_boxes` no SQLite. Esta tabela define os diferentes \"contêineres\" ou estilos visuais que podem ser aplicados aos blocos de conteúdo.

## Código da Migração (`lib/deeper/core/data/migrations/page_engine/create_sys_pages_design_boxes_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.PageEngine.CreateSysPagesDesignBoxesTable do
  @moduledoc \"Migração para criar a tabela sys_pages_design_boxes.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_pages_design_boxes...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_pages_design_boxes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      template TEXT NOT NULL,
      \"order\" INTEGER NOT NULL DEFAULT 0
    );
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_pages_design_boxes criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_pages_design_boxes: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_pages_design_boxes...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_pages_design_boxes;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_pages_design_boxes removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_pages_design_boxes: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```