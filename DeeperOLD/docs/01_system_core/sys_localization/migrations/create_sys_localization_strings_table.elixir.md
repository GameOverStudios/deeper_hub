# Migração Elixir: Criar Tabela `sys_localization_strings`

Este módulo de migração Elixir cria a tabela `sys_localization_strings` no SQLite, que armazena as traduções efetivas para cada chave em cada idioma.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_localization_strings_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysLocalizationStringsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_localization_strings.
  \"\"\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_localization_strings...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_localization_strings (
      IDKey INTEGER NOT NULL, -- FK para sys_localization_keys.ID
      IDLanguage INTEGER NOT NULL, -- FK para sys_localization_languages.ID
      String TEXT NOT NULL, -- O texto traduzido
      PRIMARY KEY (IDKey, IDLanguage),
      FOREIGN KEY (IDKey) REFERENCES sys_localization_keys(ID) ON DELETE CASCADE,
      FOREIGN KEY (IDLanguage) REFERENCES sys_localization_languages(ID) ON DELETE CASCADE
    );
    CREATE INDEX IF NOT EXISTS idx_sys_loc_strings_idlang_idkey ON sys_localization_strings(IDLanguage, IDKey);
    -- FULLTEXT KEY String (String) -- Omitido para SQLite inicial, usar FTS5 se necessário.
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_localization_strings...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_localization_strings;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```