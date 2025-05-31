# Migração Elixir: Criar Tabela `sys_acl_actions`

Este módulo de migração Elixir é responsável por criar a tabela `sys_acl_actions` no banco de dados SQLite. Esta tabela define todas as ações individuais que podem ser controladas pelo sistema de ACL.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_acl_actions_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysAclActionsTable do
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
      ID INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA original é INT(10) UNSIGNED
      Module TEXT NOT NULL, -- No UNA original é VARCHAR(32)
      Name TEXT NOT NULL, -- No UNA original é VARCHAR(255) NOT NULL DEFAULT ''
      AdditionalParamName TEXT, -- No UNA original é VARCHAR(80) DEFAULT NULL
      Title TEXT NOT NULL, -- No UNA original é VARCHAR(255)
      \"Desc\" TEXT, -- No UNA original é VARCHAR(255) NOT NULL (Desc para Description)
      Countable INTEGER NOT NULL DEFAULT 0, -- No UNA original é TINYINT(4) (0 ou 1)
      DisabledForLevels INTEGER -- No UNA original é INT(10) UNSIGNED NOT NULL DEFAULT 3 (Bitmask)
    );

    -- O FULLTEXT KEY `ModuleAndName` do MySQL não tem equivalente direto simples no SQLite.
    -- Índices separados podem ser usados para otimizar buscas.
    CREATE INDEX IF NOT EXISTS idx_sys_acl_actions_module ON sys_acl_actions(Module);
    CREATE INDEX IF NOT EXISTS idx_sys_acl_actions_name ON sys_acl_actions(Name);
    -- Um índice composto pode ser mais útil dependendo das queries
    CREATE INDEX IF NOT EXISTS idx_sys_acl_actions_module_name ON sys_acl_actions(Module, Name);
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

## Notas de Adaptação SQLite:

*   `ID`: `INT(10) UNSIGNED NOT NULL AUTO_INCREMENT` -> `INTEGER PRIMARY KEY AUTOINCREMENT`.
*   `Module`, `Name`, `AdditionalParamName`, `Title`, `Desc`: `VARCHAR` -> `TEXT`.
*   `Countable`: `TINYINT(4)` -> `INTEGER` (0 para falso, 1 para verdadeiro).
*   `DisabledForLevels`: `INT(10) UNSIGNED` -> `INTEGER`. Este campo no UNA é uma bitmask, e a lógica de interpretação da bitmask precisará ser portada para Elixir se usada.
*   **Índices:** O índice `FULLTEXT` do MySQL em `Module, Name` foi substituído por índices B-tree regulares. Se a busca full-text for necessária nesta tabela, as extensões FTS do SQLite seriam a alternativa. Um índice composto em `(Module, Name)` é geralmente útil.