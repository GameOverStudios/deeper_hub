# Migração Elixir: Criar Tabela `sys_localization_languages`

Este módulo de migração Elixir cria a tabela `sys_localization_languages` no SQLite, que define os idiomas disponíveis na plataforma.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_localization_languages_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysLocalizationLanguagesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_localization_languages.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_localization_languages...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_localization_languages (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE, -- Código curto do idioma, ex: 'en', 'pt-BR'
      Flag TEXT NOT NULL, -- Código do país para ícone, ex: 'gb', 'br'
      Title TEXT NOT NULL, -- Nome completo do idioma, ex: 'English', 'Português (Brasil)'
      Direction TEXT NOT NULL DEFAULT 'LTR' CHECK(Direction IN ('LTR', 'RTL')),
      LanguageCountry TEXT NOT NULL UNIQUE, -- Código completo, ex: 'en-GB', 'pt-BR'
      Enabled INTEGER NOT NULL DEFAULT 0 -- 0 para desabilitado, 1 para habilitado
    );
    CREATE INDEX IF NOT EXISTS idx_sys_loc_lang_name ON sys_localization_languages(Name);
    CREATE INDEX IF NOT EXISTS idx_sys_loc_lang_enabled ON sys_localization_languages(Enabled);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_localization_languages...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_localization_languages;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```