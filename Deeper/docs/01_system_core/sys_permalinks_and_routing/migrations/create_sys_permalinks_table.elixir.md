# Migração Elixir: Criar Tabela `sys_permalinks`

Este módulo de migração Elixir cria a tabela `sys_permalinks` no SQLite, que armazena os mapeamentos de URLs amigáveis (permalinks) para as URLs standard internas do sistema UNA.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_permalinks_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysPermalinksTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_permalinks.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_permalinks...\", module: __MODULE__)
    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_permalinks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      standard TEXT NOT NULL, -- URL standard, ex: 'page.php?i=view-profile&id=123'
      permalink TEXT NOT NULL UNIQUE, -- URL amigável, ex: '/profile/john-doe'
      \"check\" TEXT NOT NULL, -- Nome da classe/método PHP original no UNA (para referência)
      compare_by_prefix INTEGER NOT NULL DEFAULT 0 -- 0 ou 1
    );
    CREATE INDEX IF NOT EXISTS idx_sys_permalinks_permalink ON sys_permalinks(permalink);
    -- O schema original do UNA tem um UNIQUE KEY composto em (standard(80), permalink(80), check(30)).
    -- Para SQLite, um UNIQUE em permalink é o mais crucial para buscas.
    -- Se a combinação standard+permalink+check precisar ser única,
    -- um índice UNIQUE(standard, permalink, \"check\") pode ser adicionado.
    -- No entanto, a unicidade de 'permalink' é geralmente suficiente para a resolução.
    CREATE INDEX IF NOT EXISTS idx_sys_permalinks_standard ON sys_permalinks(standard);
    \"\"\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_permalinks...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_permalinks;\"
    case Repo.execute(sql) do
      {:ok, _} -> :ok
      err -> err
    end
  end
end
```

## Notas:

*   `standard`: A URL interna do UNA, geralmente com `page.php?i=...&param=...`.
*   `permalink`: A URL amigável que o usuário vê. Deve ser `UNIQUE`.
*   `check`: No UNA, este é o nome de uma classe/método PHP usado para validação ou para buscar o conteúdo associado ao permalink. Para a API \"Deeper\", esta coluna é mais para referência, pois não executaremos PHP.
*   `compare_by_prefix`: Indica se o matching do permalink deve considerar prefixos.