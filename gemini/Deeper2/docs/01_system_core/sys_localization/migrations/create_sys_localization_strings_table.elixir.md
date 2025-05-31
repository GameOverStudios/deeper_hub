# Migração Elixir: Criar Tabela `sys_localization_strings`

Este módulo de migração Elixir é responsável por criar a tabela `sys_localization_strings` no banco de dados SQLite. Esta tabela armazena as traduções efetivas, ligando uma chave de tradução (`IDKey`) a um idioma (`IDLanguage`) e à string traduzida correspondente.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_localization_strings_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysLocalizationStringsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_localization_strings.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_localization_strings.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_localization_strings...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_localization_strings (
      IDKey INTEGER NOT NULL,
      IDLanguage INTEGER NOT NULL,
      String TEXT NOT NULL, -- A string traduzida
      PRIMARY KEY (IDKey, IDLanguage),
      FOREIGN KEY (IDKey) REFERENCES sys_localization_keys(ID) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (IDLanguage) REFERENCES sys_localization_languages(ID) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_localization_strings_idlanguage ON sys_localization_strings(IDLanguage);
    -- O índice FULLTEXT do MySQL em `String` não é portado diretamente.
    -- Se a busca full-text nas traduções for necessária, usar as extensões FTS do SQLite.
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_localization_strings criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_localization_strings: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_localization_strings.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_localization_strings...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_localization_strings;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_localization_strings removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_localization_strings: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `IDKey`: `INT(10) UNSIGNED` (MySQL) -> `INTEGER` (SQLite). Chave estrangeira para `sys_localization_keys.ID`.
*   `IDLanguage`: `INT(10) UNSIGNED` (MySQL) -> `INTEGER` (SQLite). Chave estrangeira para `sys_localization_languages.ID`.
*   `String`: `MEDIUMTEXT` (MySQL) -> `TEXT` (SQLite).
*   **Chave Primária Composta:** `PRIMARY KEY (IDKey, IDLanguage)` garante que cada chave tenha no máximo uma tradução por idioma.
*   **Chaves Estrangeiras:** Definidas para `IDKey` e `IDLanguage`.
*   **Índice Full-Text:** O índice `FULLTEXT` do MySQL na coluna `String` foi omitido. Se a funcionalidade de busca dentro das strings traduzidas for necessária, as extensões FTS (FTS3/4/5) do SQLite deverão ser consideradas e implementadas separadamente.