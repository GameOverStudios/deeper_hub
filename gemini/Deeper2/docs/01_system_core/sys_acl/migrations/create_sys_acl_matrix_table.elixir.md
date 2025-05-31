# Migração Elixir: Criar Tabela `sys_acl_matrix`

Este módulo de migração Elixir é responsável por criar a tabela `sys_acl_matrix` no banco de dados SQLite. Esta é uma tabela crucial que define as permissões, especificando quais níveis de ACL (`IDLevel`) podem realizar quais ações (`IDAction`) e sob quais condições (contagem, período).

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_acl_matrix_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysAclMatrixTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_matrix.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_acl_matrix.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_matrix...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_matrix (
      IDLevel INTEGER NOT NULL, -- No UNA é INT(10) UNSIGNED, FK para sys_acl_levels.ID
      IDAction INTEGER NOT NULL, -- No UNA é INT(10) UNSIGNED, FK para sys_acl_actions.ID
      AllowedCount INTEGER, -- No UNA é INT(10) UNSIGNED DEFAULT NULL (NULL significa ilimitado)
      AllowedPeriodLen INTEGER, -- No UNA é INT(10) UNSIGNED DEFAULT NULL (em segundos)
      AllowedPeriodStart TEXT, -- No UNA é DATETIME DEFAULT NULL, armazenar como ISO8601
      AllowedPeriodEnd TEXT, -- No UNA é DATETIME DEFAULT NULL, armazenar como ISO8601
      AdditionalParamValue TEXT, -- No UNA é VARCHAR(255) DEFAULT NULL
      PRIMARY KEY (IDLevel, IDAction),
      FOREIGN KEY (IDLevel) REFERENCES sys_acl_levels(ID) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (IDAction) REFERENCES sys_acl_actions(ID) ON DELETE CASCADE ON UPDATE CASCADE
    );
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_matrix criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_acl_matrix: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_acl_matrix.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_matrix...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_acl_matrix;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_matrix removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_acl_matrix: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `IDLevel`, `IDAction`, `AllowedCount`, `AllowedPeriodLen`: `INT(10) UNSIGNED` (MySQL) -> `INTEGER` (SQLite). `AllowedCount` e `AllowedPeriodLen` podem ser `NULL`.
*   `AllowedPeriodStart`, `AllowedPeriodEnd`: `DATETIME DEFAULT NULL` (MySQL) -> `TEXT` (SQLite), armazenando datas/horas no formato ISO 8601, permitindo `NULL`.
*   `AdditionalParamValue`: `VARCHAR(255) DEFAULT NULL` (MySQL) -> `TEXT` (SQLite), permitindo `NULL`.
*   **Chave Primária Composta:** `PRIMARY KEY (IDLevel, IDAction)` foi mantida, garantindo que cada combinação de nível e ação tenha apenas uma entrada de regra de permissão.
*   **Chaves Estrangeiras:** Definidas para `IDLevel` e `IDAction`.