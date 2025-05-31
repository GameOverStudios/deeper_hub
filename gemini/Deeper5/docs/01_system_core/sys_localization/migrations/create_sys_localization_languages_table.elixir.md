# Migração Elixir: Criar Tabela `sys_localization_languages`

Este módulo de migração Elixir cria a tabela `sys_localization_languages` no SQLite, que define os idiomas disponíveis no sistema.

## Código da Migração (`lib/deeper/core/data/migrations/localization/create_sys_localization_languages_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.Localization.CreateSysLocalizationLanguagesTable do
  @moduledoc \"Migração para criar a tabela sys_localization_languages.\"
  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  def up do
    Logger.info(\"Criando tabela sys_localization_languages...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_localization_languages (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE,
      Flag TEXT,
      Title TEXT NOT NULL,
      Direction TEXT NOT NULL DEFAULT 'LTR' CHECK(Direction IN ('LTR', 'RTL')),
      LanguageCountry TEXT,
      Enabled INTEGER NOT NULL DEFAULT 0
    );
    \"\"\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_localization_languages criada com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao criar tabela sys_localization_languages: #{inspect(reason)}\", module: __MODULE__)
    end)
  end

  def down do
    Logger.info(\"Removendo tabela sys_localization_languages...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_localization_languages;\"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info(\"Tabela sys_localization_languages removida com sucesso.\", module: __MODULE__)
      {:error, reason} -> Logger.error(\"Falha ao remover tabela sys_localization_languages: #{inspect(reason)}\", module: __MODULE__)
    end)
  end
end
```