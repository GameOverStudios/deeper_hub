# Migração Elixir: Criar Tabela `sys_form_pre_values`

Este módulo de migração Elixir cria a tabela `sys_form_pre_values` no SQLite. Esta tabela armazena os valores individuais para cada lista definida em `sys_form_pre_lists`.

## Código da Migração (`lib/deeper/core/data/migrations/forms_engine/create_sys_form_pre_values_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.FormsEngine.CreateSysFormPreValuesTable do
  @moduledoc \"Migração para criar a tabela sys_form_pre_values.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_form_pre_values...\", module: __MODULE__)
    # Repo.execute(\"PRAGMA foreign_keys = ON;\") # Se for adicionar FK para sys_form_pre_lists.key_name
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_pre_values (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      list_key_name TEXT NOT NULL, -- No UNA é `Key`
      value TEXT NOT NULL,
      \"order\" INTEGER NOT NULL DEFAULT 0,
      lkey TEXT NOT NULL,
      lkey2 TEXT,
      data TEXT
      -- FOREIGN KEY (list_key_name) REFERENCES sys_form_pre_lists(key_name) ON DELETE CASCADE ON UPDATE CASCADE
      -- (A FK acima não pode ser usada diretamente se key_name não for PRIMARY KEY em sys_form_pre_lists,
      --  mas sim UNIQUE. SQLite permite FK para colunas UNIQUE. A aplicação garante a relação.)
    );
    CREATE INDEX IF NOT EXISTS idx_sfpv_list_key_order ON sys_form_pre_values(list_key_name, \"order\");
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_form_pre_values criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_form_pre_values: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_form_pre_values...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_pre_values;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_form_pre_values removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_form_pre_values: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```