# Migração Elixir: Criar Tabela `sys_acl_actions`

Este módulo de migração Elixir cria a tabela `sys_acl_actions` no SQLite, que define as ações específicas que podem ser controladas por permissões no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_acl_actions_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysAclActionsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_actions.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_actions...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_actions (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Module TEXT NOT NULL,
      Name TEXT NOT NULL DEFAULT '',
      AdditionalParamName TEXT, -- Pode ser NULL
      Title TEXT NOT NULL, -- Chave de tradução
      \"Desc\" TEXT NOT NULL DEFAULT '', -- Chave de tradução para descrição (Aspas para 'Desc')
      Countable INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      DisabledForLevels INTEGER NOT NULL DEFAULT 3 -- Máscara de bits; 3 = Visitante e Não-Membro no UNA
      -- UNIQUE (Module, Name) -- Uma ação deve ser única por módulo e nome
    );
    -- O FULLTEXT KEY em (Module, Name) do dump original é omitido.
    -- Um índice UNIQUE seria mais apropriado para a lógica da aplicação.
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_acl_actions_module_name ON sys_acl_actions(Module, Name);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_actions...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_acl_actions;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```