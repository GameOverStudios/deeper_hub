# Migração Elixir: Criar Tabela `sys_pages_design_boxes`

Este módulo de migração Elixir é responsável por criar a tabela `sys_pages_design_boxes` no banco de dados SQLite. Esta tabela define os diferentes estilos visuais (também conhecidos como \"design boxes\" ou \"caixas de design\") que podem ser aplicados aos blocos de conteúdo nas páginas.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_pages_design_boxes_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysPagesDesignBoxesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_pages_design_boxes.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_pages_design_boxes.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_pages_design_boxes...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_pages_design_boxes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      template TEXT NOT NULL, -- Nome do arquivo de template para o design box
      \"order\" INTEGER NOT NULL
    );
    \"\"\"
    # Não há índices óbvios além da PK nesta tabela no dump original.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_pages_design_boxes criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_pages_design_boxes: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_pages_design_boxes.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_pages_design_boxes...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_pages_design_boxes;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_pages_design_boxes removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_pages_design_boxes: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11)` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `title`, `template`: `VARCHAR(255)` (MySQL) -> `TEXT` (SQLite).
*   `order`: `INT(11)` (MySQL) -> `INTEGER` (SQLite). Colocado entre aspas (`\"order\"`).