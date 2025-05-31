# Migração Elixir: Criar Tabela `sys_options_mixes`

Este módulo de migração Elixir é responsável por criar a tabela `sys_options_mixes` no banco de dados SQLite. Esta tabela define \"mixes\" de configurações, que são frequentemente usados para implementar temas ou conjuntos de configurações pré-definidas que podem sobrescrever os valores padrão das opções.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_options_mixes_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysOptionsMixesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_options_mixes.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_options_mixes.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_options_mixes...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_options_mixes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL, -- Ex: 'template', 'language'
      category TEXT NOT NULL, -- Para agrupar mixes, ex: 'Light Themes'
      name TEXT NOT NULL UNIQUE, -- Nome do mix, ex: 'lucid_light'
      title TEXT NOT NULL, -- Título amigável do mix
      dark INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      active INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, indica se é o mix globalmente ativo para seu tipo
      published INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      editable INTEGER NOT NULL DEFAULT 1 -- 0 ou 1
    );

    CREATE INDEX IF NOT EXISTS idx_sys_options_mixes_type_active ON sys_options_mixes(type, active);
    CREATE INDEX IF NOT EXISTS idx_sys_options_mixes_name ON sys_options_mixes(name);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_options_mixes criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_options_mixes: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_options_mixes.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_options_mixes...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_options_mixes;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_options_mixes removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_options_mixes: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11) UNSIGNED AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `type`, `category`, `name`, `title`: `VARCHAR(64)` (MySQL) -> `TEXT` (SQLite). `name` é `UNIQUE`.
*   `dark`, `active`, `published`, `editable`: `TINYINT(1)` (MySQL) -> `INTEGER` (SQLite), (0 para false, 1 para true).