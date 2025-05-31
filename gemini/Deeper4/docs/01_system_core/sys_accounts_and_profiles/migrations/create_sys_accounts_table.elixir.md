# Migração Elixir: Criar Tabela `sys_accounts`

Este módulo de migração Elixir é responsável por criar a tabela `sys_accounts` no banco de dados SQLite. Esta tabela armazena informações de login, dados básicos da conta e status do usuário.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_accounts_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysAccountsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_accounts.
  \"\"\"

  alias Deeper.Core.Data.Repo # Assumindo que este é o seu módulo de acesso ao DB
  alias Deeper.Core.Logger    # Assumindo que este é o seu módulo de logging
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_accounts.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_accounts...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      email_confirmed INTEGER NOT NULL DEFAULT 0,
      phone TEXT,
      phone_confirmed INTEGER NOT NULL DEFAULT 0,
      receive_updates INTEGER NOT NULL DEFAULT 1,
      receive_news INTEGER NOT NULL DEFAULT 1,
      password_hash TEXT NOT NULL,
      role INTEGER NOT NULL DEFAULT 1,
      lang_id INTEGER DEFAULT 0,
      added INTEGER NOT NULL, -- Unix Timestamp
      changed INTEGER NOT NULL, -- Unix Timestamp
      logged INTEGER, -- Unix Timestamp
      ip TEXT,
      referred TEXT,
      login_attempts INTEGER NOT NULL DEFAULT 0,
      locked INTEGER NOT NULL DEFAULT 0,
      active INTEGER NOT NULL DEFAULT 0
    );

    CREATE INDEX IF NOT EXISTS idx_sys_accounts_email ON sys_accounts(email);
    CREATE INDEX IF NOT EXISTS idx_sys_accounts_profile_id ON sys_accounts(profile_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_accounts criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_accounts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_accounts.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_accounts...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_accounts;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_accounts removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_accounts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   O tipo `INTEGER PRIMARY KEY AUTOINCREMENT` é usado para `id` no SQLite.
*   Colunas booleanas (`email_confirmed`, `locked`, `active`, etc.) são representadas como `INTEGER` com `0` (falso) e `1` (verdadeiro).
*   Timestamps (`added`, `changed`, `logged`) são armazenados como `INTEGER` (Unix Timestamps).
*   A chave estrangeira para `profile_id` será definida na migração da tabela `sys_profiles` ou gerenciada pela lógica da aplicação, dependendo da estratégia de criação de tabelas interdependentes.