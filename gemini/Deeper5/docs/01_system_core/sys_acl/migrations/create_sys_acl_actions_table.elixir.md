# Migração Elixir: Criar Tabela `sys_acl_actions`

Este módulo de migração Elixir é responsável por criar a tabela `sys_acl_actions` no banco de dados SQLite. Esta tabela define as ações específicas dentro do sistema que podem ser controladas por permissões de ACL.

## Código da Migração (`lib/deeper/core/data/migrations/acl/create_sys_acl_actions_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.ACL.CreateSysAclActionsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_actions.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_acl_actions.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_actions...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_actions (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Module TEXT NOT NULL,
      Name TEXT NOT NULL,
      AdditionalParamName TEXT,
      Title TEXT NOT NULL,
      \"Desc\" TEXT,
      Countable INTEGER NOT NULL DEFAULT 0,
      DisabledForLevels INTEGER NOT NULL DEFAULT 3
    );

    -- Este índice garante que a combinação de Módulo, Nome da Ação,
    -- e Parâmetro Adicional (se houver) seja única.
    -- SQLite trata NULL como diferente de outros NULLs em UNIQUE constraints,
    -- o que é o comportamento desejado aqui.
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_acl_actions_module_name_param
    ON sys_acl_actions(Module, Name, AdditionalParamName);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_actions criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_acl_actions: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_acl_actions.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_actions...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_acl_actions;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_actions removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_acl_actions: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `Module` e `Name` identificam a ação (ex: `Module='bx_persons'`, `Name='view_profile'`).
*   `AdditionalParamName` permite uma granularidade maior se duas ações no mesmo módulo com o mesmo nome precisarem de permissões diferentes baseadas em um parâmetro.
*   `Title` e `\"Desc\"` (Descrição) são geralmente chaves de tradução para a UI.
*   `Countable` indica se a ação tem um limite de uso.
*   `DisabledForLevels` é um bitmask dos `ID`s de `sys_acl_levels` para os quais esta ação é incondicionalmente desabilitada.
*   O índice `UNIQUE` em `(Module, Name, AdditionalParamName)` garante que cada ação seja definida de forma única.