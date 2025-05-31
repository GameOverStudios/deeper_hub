# Migração Elixir: Criar Tabela `sys_form_pre_values`

Este módulo de migração Elixir cria a tabela `sys_form_pre_values` no SQLite, que armazena os valores e legendas individuais para as listas pré-definidas em `sys_form_pre_lists`.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_form_pre_values_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysFormPreValuesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_form_pre_values.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_form_pre_values...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_form_pre_values (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      \"Key\" TEXT NOT NULL, -- FK para sys_form_pre_lists.key (com aspas)
      Value TEXT NOT NULL, -- O valor real do item da lista
      \"Order\" INTEGER NOT NULL DEFAULT 0, -- Ordem de exibição
      LKey TEXT NOT NULL, -- Chave de tradução para a legenda do item
      LKey2 TEXT NOT NULL DEFAULT '', -- Chave de tradução secundária (opcional)
      Data TEXT NOT NULL DEFAULT '' -- Dados extras associados ao valor (JSON)
      -- FOREIGN KEY (\"Key\") REFERENCES sys_form_pre_lists(\"key\") ON DELETE CASCADE -- Opcional
    );
    CREATE INDEX IF NOT EXISTS idx_sys_form_pre_values_key_order ON sys_form_pre_values(\"Key\", \"Order\");
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_form_pre_values...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_form_pre_values;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```