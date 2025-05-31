# Migração Elixir: Criar Tabela `sys_acl_actions_track`

Este módulo de migração Elixir é responsável por criar a tabela `sys_acl_actions_track` no banco de dados SQLite. Esta tabela rastreia o uso de ações contáveis pelos membros, armazenando quantas ações restam e quando o período de contagem se renova.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_acl_actions_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysAclActionsTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_actions_track.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_acl_actions_track.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_acl_actions_track...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_actions_track (
      IDAction INTEGER NOT NULL, -- No UNA é INT(10) UNSIGNED, FK para sys_acl_actions.ID
      IDMember INTEGER NOT NULL, -- No UNA é INT(10) UNSIGNED, FK para sys_accounts.id
      ActionsLeft INTEGER NOT NULL, -- No UNA é INT(10) UNSIGNED NOT NULL DEFAULT 0
      ValidSince TEXT, -- No UNA é DATETIME DEFAULT NULL, armazenar como ISO8601
      PRIMARY KEY (IDAction, IDMember),
      FOREIGN KEY (IDAction) REFERENCES sys_acl_actions(ID) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (IDMember) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE
    );
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_actions_track criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_acl_actions_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_acl_actions_track.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_acl_actions_track...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_acl_actions_track;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_acl_actions_track removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_acl_actions_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `IDAction`, `IDMember`, `ActionsLeft`: `INT(10) UNSIGNED` (MySQL) -> `INTEGER` (SQLite).
*   `ValidSince`: `DATETIME DEFAULT NULL` (MySQL) -> `TEXT` (SQLite), armazenando data/hora no formato ISO 8601, permitindo `NULL`.
*   **Chave Primária Composta:** `PRIMARY KEY (IDAction, IDMember)` foi mantida.
*   **Chaves Estrangeiras:** Definidas para `IDAction` e `IDMember`.