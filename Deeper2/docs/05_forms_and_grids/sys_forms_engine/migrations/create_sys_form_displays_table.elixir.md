# Migração Elixir: Criar Tabela `sys_form_displays`

Este módulo de migração Elixir é responsável por criar a tabela `sys_form_displays` no banco de dados SQLite. Esta tabela define diferentes \"exibições\" ou contextos para um mesmo formulário base (definido em `sys_objects_form`), como \"formulário de adição\", \"formulário de edição\", etc. Cada exibição pode mostrar um conjunto diferente de campos ou ter títulos diferentes.

**Dependências:** `sys_objects_form`

## Código da Migração (`lib/deeper/forms/migrations/create_sys_form_displays_table.ex`)

```elixir
defmodule Deeper.Forms.Migrations.CreateSysFormDisplaysTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_form_displays.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_form_displays.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_form_displays...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_displays (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      display_name TEXT NOT NULL, -- Nome da exibição, ex: 'bx_persons_add', 'bx_persons_edit_profile'
      module TEXT NOT NULL,
      object TEXT NOT NULL, -- FK para sys_objects_form.object
      title TEXT NOT NULL, -- Título da exibição
      view_mode INTEGER NOT NULL DEFAULT 0, -- 0 para HTML, 1 para JSON no UNA
      FOREIGN KEY (object) REFERENCES sys_objects_form(object) ON DELETE CASCADE ON UPDATE CASCADE
      -- FK para module (sys_modules.name)
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_form_displays_object_display_name ON sys_form_displays(object, display_name);
    CREATE INDEX IF NOT EXISTS idx_sys_form_displays_module ON sys_form_displays(module);
    CREATE INDEX IF NOT EXISTS idx_sys_form_displays_display_name ON sys_form_displays(display_name); -- Para buscas por display_name
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_form_displays criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_form_displays: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_form_displays.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_form_displays...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_displays;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_form_displays removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_form_displays: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11)` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT`.
*   `display_name`, `module`, `object`, `title`: `VARCHAR` (MySQL) -> `TEXT`.
*   `view_mode`: `TINYINT(4)` (MySQL) -> `INTEGER`.
*   **Índice Único:** `uidx_sys_form_displays_object_display_name` garante que um `display_name` seja único dentro do escopo de um `object` de formulário.
*   **Chave Estrangeira:** `object` para `sys_objects_form.object`.