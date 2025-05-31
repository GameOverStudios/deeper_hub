# Migração Elixir: Criar Tabela `sys_form_display_inputs`

Este módulo de migração Elixir é responsável por criar a tabela `sys_form_display_inputs` no banco de dados SQLite. Esta tabela de junção controla quais campos de entrada (`sys_form_inputs`) são visíveis e em que ordem aparecem para uma exibição de formulário específica (`sys_form_displays`).

**Dependências Conceituais:** `sys_form_displays` (via `display_name` + `object` implícito do formulário) e `sys_form_inputs` (via `input_name` + `object` implícito do formulário).

## Código da Migração (`lib/deeper/forms/migrations/create_sys_form_display_inputs_table.ex`)

```elixir
defmodule Deeper.Forms.Migrations.CreateSysFormDisplayInputsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_form_display_inputs.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_form_display_inputs.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_form_display_inputs...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_display_inputs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      display_name TEXT NOT NULL, -- Refere-se a sys_form_displays.display_name
      input_name TEXT NOT NULL, -- Refere-se a sys_form_inputs.name (dentro do mesmo form 'object')
      visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Bitmask ACL
      active INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se o campo está visível/ativo nesta exibição)
      \"order\" INTEGER NOT NULL
      -- No UNA, a ligação é implícita pelo contexto do 'object' do formulário.
      -- Para FKs explícitas, seria necessário um 'form_object' aqui ou uma PK diferente
      -- em sys_form_displays e sys_form_inputs para referência direta.
    );

    -- Índice para buscar inputs de um display, ordenados.
    CREATE INDEX IF NOT EXISTS idx_sys_form_display_inputs_display_order ON sys_form_display_inputs(display_name, \"order\");
    -- Garante que um input_name não apareça duas vezes no mesmo display_name.
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_form_display_inputs_display_input ON sys_form_display_inputs(display_name, input_name);
    CREATE INDEX IF NOT EXISTS idx_sys_form_display_inputs_input_name ON sys_form_display_inputs(input_name);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_form_display_inputs criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_form_display_inputs: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_form_display_inputs.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_form_display_inputs...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_display_inputs;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_form_display_inputs removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_form_display_inputs: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`, `visible_for_levels`, `order`: `INT(11)` (MySQL) -> `INTEGER` (SQLite). `id` é `PK AUTOINCREMENT`. `order` está entre aspas.
*   `display_name`, `input_name`: `VARCHAR` (MySQL) -> `TEXT`.
*   `active`: `TINYINT(4)` (MySQL) -> `INTEGER` (0 ou 1).
*   **Chaves Estrangeiras:** No esquema original do UNA, as ligações com `sys_form_displays` e `sys_form_inputs` são feitas pelos seus respectivos nomes (`display_name`, `input_name`) dentro do contexto do `object` do formulário ao qual o display e o input pertencem. Implementar FKs diretas aqui exigiria que `sys_form_displays.display_name` e `sys_form_inputs.name` fossem chaves únicas globais (o que não são) ou que esta tabela incluísse o `form_object` e as FKs fossem compostas. Para a API \"Deeper\", a lógica de junção no `FormsRepo` considerará o `form_object` implícito.
*   **Índice Único:** `uidx_sys_form_display_inputs_display_input` garante que um `input_name` seja único dentro de um `display_name`.