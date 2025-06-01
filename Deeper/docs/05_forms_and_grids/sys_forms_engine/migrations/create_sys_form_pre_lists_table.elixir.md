# Migração Elixir: Criar Tabela `sys_form_pre_lists`

Este módulo de migração Elixir cria a tabela `sys_form_pre_lists` no SQLite, usada para definir conjuntos de valores pré-definidos que podem ser usados em campos de formulário como selects, radios, etc.

## Código da Migração (`lib/deeper/core/data/migrations/forms_engine/create_sys_form_pre_lists_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.FormsEngine.CreateSysFormPreListsTable do
  @moduledoc \"Migração para criar a tabela sys_form_pre_lists.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_form_pre_lists...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_pre_lists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      module TEXT NOT NULL DEFAULT '',
      key_name TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      use_for_sets INTEGER NOT NULL DEFAULT 1,
      extendable INTEGER NOT NULL DEFAULT 1
    );
    \"\"\"
    # O índice em key_name é criado pela constraint UNIQUE.
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_form_pre_lists criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_form_pre_lists: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_form_pre_lists...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_pre_lists;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_form_pre_lists removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_form_pre_lists: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```