# Migração Elixir: Criar Tabela `sys_rewrite_rules`

Este módulo de migração Elixir é responsável por criar a tabela `sys_rewrite_rules` no banco de dados SQLite. Esta tabela armazena regras de reescrita de URL baseadas em expressões regulares, que no UNA PHP disparam chamadas de serviço.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_rewrite_rules_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysRewriteRulesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_rewrite_rules.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_rewrite_rules.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_rewrite_rules...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_rewrite_rules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      preg TEXT NOT NULL, -- Expressão regular
      service TEXT NOT NULL, -- Chamada de serviço PHP serializada
      active INTEGER NOT NULL DEFAULT 1 -- 0 ou 1
    );
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_rewrite_rules criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_rewrite_rules: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_rewrite_rules.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_rewrite_rules...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_rewrite_rules;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_rewrite_rules removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_rewrite_rules: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(10) UNSIGNED AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `preg`, `service`: `VARCHAR(255)` (MySQL) -> `TEXT` (SQLite).
*   `active`: `TINYINT(4)` (MySQL) -> `INTEGER` (SQLite).
*   A coluna `service` contém dados que são específicos da implementação PHP do UNA. A API \"Deeper\" precisaria de uma lógica customizada para interpretar ou utilizar essas regras, se for o caso.