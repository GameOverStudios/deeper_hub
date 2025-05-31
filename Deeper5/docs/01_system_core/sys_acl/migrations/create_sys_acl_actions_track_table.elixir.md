# Migração Elixir: Criar Tabela `sys_acl_actions_track`

Este módulo de migração Elixir é responsável por criar a tabela `sys_acl_actions_track` no banco de dados SQLite. Esta tabela rastreia o uso de ações contáveis (`sys_acl_actions` onde `Countable = 1`) por cada membro (`sys_accounts.id`).

## Código da Migração (`lib/deeper/core/data/migrations/acl/create_sys_acl_actions_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.ACL.CreateSysAclActionsTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_acl_actions_track.
  Depende da existência das tabelas `sys_acl_actions` e `sys_accounts`.
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

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_acl_actions_track (
      IDAction INTEGER NOT NULL,
      IDMember INTEGER NOT NULL,
      ActionsLeft INTEGER NOT NULL,
      ValidSince INTEGER, -- Unix Timestamp: quando o período de contagem/ActionsLeft foi (re)iniciado
      PRIMARY KEY (IDAction, IDMember),
      FOREIGN KEY (IDAction) REFERENCES sys_acl_actions(ID) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (IDMember) REFERENCES sys_accounts(id) ON DELETE CASCADE ON UPDATE CASCADE
    );
    \"\"\"
    # Repo.execute(\"PRAGMA foreign_keys = ON;\")

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

## Notas:

*   A chave primária `(IDAction, IDMember)` identifica unicamente o rastreamento de uma ação para um membro.
*   `ActionsLeft` armazena o número de execuções restantes da ação.
*   `ValidSince` é um Timestamp Unix que marca o início do período de validade para `ActionsLeft`. É usado em conjunto com `sys_acl_matrix.AllowedPeriodLen` para determinar se o contador precisa ser resetado.