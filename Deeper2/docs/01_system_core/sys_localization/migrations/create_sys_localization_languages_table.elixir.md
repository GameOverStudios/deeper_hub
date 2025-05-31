# Migração Elixir: Criar Tabela `sys_localization_languages`

Este módulo de migração Elixir é responsável por criar a tabela `sys_localization_languages` no banco de dados SQLite. Esta tabela define os idiomas suportados pelo sistema, como inglês, português, etc., juntamente com seus metadados.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_localization_languages_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysLocalizationLanguagesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_localization_languages.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_localization_languages.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_localization_languages...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_localization_languages (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE, -- Código do idioma, ex: 'en'
      Flag TEXT, -- Código do país para flag, ex: 'us'
      Title TEXT NOT NULL, -- Nome amigável, ex: 'English'
      Direction TEXT NOT NULL DEFAULT 'LTR' CHECK(Direction IN ('LTR', 'RTL')),
      LanguageCountry TEXT, -- Código completo ex: 'en-US'
      Enabled INTEGER NOT NULL DEFAULT 0 -- 0 for false, 1 for true
    );

    CREATE INDEX IF NOT EXISTS idx_sys_localization_languages_name ON sys_localization_languages(Name);
    CREATE INDEX IF NOT EXISTS idx_sys_localization_languages_enabled ON sys_localization_languages(Enabled);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_localization_languages criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_localization_languages: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_localization_languages.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_localization_languages...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_localization_languages;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_localization_languages removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_localization_languages: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `ID`: `INT(10) UNSIGNED AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `Name`, `Flag`, `Title`, `LanguageCountry`: `VARCHAR` (MySQL) -> `TEXT` (SQLite). `Name` é `UNIQUE`.
*   `Direction`: `ENUM('LTR','RTL')` (MySQL) -> `TEXT CHECK(Direction IN ('LTR', 'RTL'))` (SQLite).
*   `Enabled`: `TINYINT(1) UNSIGNED` (MySQL) -> `INTEGER` (SQLite), (0 para false, 1 para true).