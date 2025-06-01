# Migração Elixir: Criar Tabela `sys_options_mixes2options`

Este módulo de migração Elixir é responsável por criar a tabela `sys_options_mixes2options` no banco de dados SQLite. Esta é uma tabela de junção que armazena os valores específicos das opções para cada \"mix\" definido em `sys_options_mixes`. Se um mix estiver ativo, os valores nesta tabela para esse mix sobrescrevem os valores padrão de `sys_options`.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_options_mixes2options_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysOptionsMixes2OptionsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_options_mixes2options.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_options_mixes2options.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_options_mixes2options...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_options_mixes2options (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      option_name TEXT NOT NULL, -- Refere-se a sys_options.name
      mix_id INTEGER NOT NULL,
      value TEXT NOT NULL, -- Valor da opção para este mix específico
      FOREIGN KEY (mix_id) REFERENCES sys_options_mixes(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_options_mixes2options_mix_id ON sys_options_mixes2options(mix_id);
    CREATE INDEX IF NOT EXISTS idx_sys_options_mixes2options_option_name ON sys_options_mixes2options(option_name);
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_options_mixes2options_option_mix ON sys_options_mixes2options(option_name, mix_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_options_mixes2options criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_options_mixes2options: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_options_mixes2options.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_options_mixes2options...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_options_mixes2options;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_options_mixes2options removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_options_mixes2options: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11)` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `option_name`: `VARCHAR(64)` (MySQL) -> `TEXT` (SQLite). Conceitualmente refere-se a `sys_options.name`.
*   `mix_id`: `INT(11) UNSIGNED` (MySQL) -> `INTEGER` (SQLite). Chave estrangeira para `sys_options_mixes.id`.
*   `value`: `MEDIUMTEXT` (MySQL) -> `TEXT` (SQLite).
*   **Chave Estrangeira:** Definida para `mix_id`.
*   **Índice Único:** `uidx_sys_options_mixes2options_option_mix` garante que uma opção não possa ter múltiplos valores para o mesmo mix.