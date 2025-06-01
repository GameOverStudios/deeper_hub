# Migração Elixir: (Exemplo) Criar Tabela de Conteúdo de Comentários (`example_module_cmts`)

Este módulo de migração Elixir é um **exemplo** de como uma tabela de conteúdo de comentários, cujo nome seria especificado em `sys_objects_cmts.\"Table\"`, seria criada. **O nome real da tabela (`example_module_cmts` aqui) seria dinâmico.**

Para cada entrada em `sys_objects_cmts`, uma tabela correspondente ao valor de `sys_objects_cmts.\"Table\"` precisaria existir com uma estrutura similar a esta.

**Dependências:** `sys_profiles` (para `cmt_author_id`)

## Código da Migração (`lib/deeper/interaction_systems/comments/migrations/create_example_module_cmts_table.ex`)

```elixir
defmodule Deeper.InteractionSystems.Comments.Migrations.CreateExampleModuleCmtsTable do
  @moduledoc \"\"\"
  Migração EXEMPLO para criar uma tabela de conteúdo de comentários.
  O nome real da tabela viria de sys_objects_cmts.\"Table\".
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @table_name \"example_module_cmts\" # Este nome seria dinâmico

  @doc \"\"\"
  Executa a migração para criar a tabela de exemplo.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela de exemplo de comentários: #{@table_name}...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS #{@table_name} (
      cmt_id INTEGER PRIMARY KEY AUTOINCREMENT,
      cmt_parent_id INTEGER NOT NULL DEFAULT 0,
      cmt_vparent_id INTEGER NOT NULL DEFAULT 0,
      cmt_object_id INTEGER NOT NULL, -- ID do item de conteúdo sendo comentado
      cmt_author_id INTEGER NOT NULL, -- FK para sys_profiles.id
      cmt_level INTEGER NOT NULL DEFAULT 0,
      cmt_text TEXT NOT NULL,
      cmt_mood INTEGER NOT NULL DEFAULT 0,
      cmt_time INTEGER NOT NULL, -- Unix Timestamp
      cmt_replies INTEGER NOT NULL DEFAULT 0,
      cmt_pinned INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (cmt_author_id) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE
      -- FK para cmt_parent_id (auto-referência a esta tabela cmt_id)
      -- FOREIGN KEY (cmt_parent_id) REFERENCES #{@table_name}(cmt_id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_object_parent ON #{@table_name}(cmt_object_id, cmt_parent_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_vparent ON #{@table_name}(cmt_vparent_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_author_id ON #{@table_name}(cmt_author_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela #{@table_name} criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela #{@table_name}: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela de exemplo.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela #{@table_name}...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS #{@table_name};\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela #{@table_name} removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela #{@table_name}: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   A estrutura é similar à tabela `bx_persons_cmts` que definimos anteriormente, caso o UNA use tabelas de comentários específicas por módulo.
*   `cmt_id`, `cmt_parent_id`, `cmt_vparent_id`, `cmt_object_id`, `cmt_author_id`, `cmt_level`, `cmt_mood`, `cmt_time`, `cmt_replies`, `cmt_pinned`: `INT` ou `TINYINT` (MySQL) -> `INTEGER` (SQLite). `cmt_time` é Unix Timestamp.
*   `cmt_text`: `TEXT` (MySQL) -> `TEXT` (SQLite).
*   **Nome da Tabela Dinâmico:** A string `@table_name` é usada para demonstrar que o nome da tabela é variável. Na prática, um sistema de migração para \"Deeper\" precisaria de uma estratégia para criar essas tabelas com base nos valores de `sys_objects_cmts.\"Table\"` existentes no banco de dados UNA original.
*   **Chave Estrangeira para `cmt_parent_id`:** A FK auto-referencial para `cmt_parent_id` é mostrada comentada. SQLite suporta isso.