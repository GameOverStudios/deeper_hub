# Migração Elixir: Criar Tabela `sys_acl_levels`

Este módulo de migração Elixir é responsável por criar a tabela `sys_acl_levels` no banco de dados SQLite. Esta tabela define os diferentes níveis de membresia ou papéis que os usuários podem ter no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_acl_levels_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysAclLevelsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_levels.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_acl_levels.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_levels...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_levels (
      ID INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA original é INT(10) UNSIGNED
      Name TEXT NOT NULL UNIQUE,
      Icon TEXT, -- No UNA original é TEXT NOT NULL DEFAULT ''
      Description TEXT, -- No UNA original é VARCHAR(255) NOT NULL DEFAULT ''
      Active TEXT NOT NULL DEFAULT 'no' CHECK(Active IN ('yes', 'no')), -- ENUM('yes','no')
      Purchasable TEXT NOT NULL DEFAULT 'yes' CHECK(Purchasable IN ('yes', 'no')), -- ENUM('yes','no')
      Removable TEXT NOT NULL DEFAULT 'yes' CHECK(Removable IN ('yes', 'no')), -- ENUM('yes','no')
      QuotaSize INTEGER, -- No UNA original é BIGINT(20) NOT NULL
      QuotaNumber INTEGER, -- No UNA original é INT(11) NOT NULL
      QuotaMaxFileSize INTEGER, -- No UNA original é BIGINT(20) NOT NULL
      \"Order\" INTEGER NOT NULL DEFAULT 0, -- \"Order\" entre aspas por ser palavra reservada
      PasswordExpired INTEGER NOT NULL DEFAULT 0, -- No UNA original é INT(11)
      PasswordExpiredNotify INTEGER NOT NULL DEFAULT 0 -- No UNA original é INT(11)
    );

    CREATE INDEX IF NOT EXISTS idx_sys_acl_levels_name ON sys_acl_levels(Name);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_levels criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_acl_levels: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_acl_levels.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_levels...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_acl_levels;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_levels removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_acl_levels: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `ID`: `INT(10) UNSIGNED NOT NULL AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `Name`: `VARCHAR(100) NOT NULL DEFAULT ''` com `UNIQUE KEY` (MySQL) -> `TEXT NOT NULL UNIQUE` (SQLite).
*   `Icon`, `Description`: `TEXT` e `VARCHAR(255)` (MySQL) -> `TEXT` (SQLite). `NOT NULL DEFAULT ''` foi simplificado para `NULL` ou gerenciado pela aplicação se um valor padrão for estritamente necessário na inserção.
*   `Active`, `Purchasable`, `Removable`: `ENUM('yes','no')` (MySQL) -> `TEXT CHECK(Column IN ('yes', 'no'))` (SQLite). O `DEFAULT` foi mantido.
*   `QuotaSize`, `QuotaMaxFileSize`: `BIGINT(20)` (MySQL) -> `INTEGER` (SQLite, que pode armazenar inteiros grandes).
*   `QuotaNumber`, `PasswordExpired`, `PasswordExpiredNotify`: `INT(11)` (MySQL) -> `INTEGER` (SQLite).
*   `Order`: `INT(11)` (MySQL) -> `INTEGER` (SQLite). O nome da coluna foi colocado entre aspas duplas (`\"Order\"`) porque `ORDER` é uma palavra reservada em SQL.