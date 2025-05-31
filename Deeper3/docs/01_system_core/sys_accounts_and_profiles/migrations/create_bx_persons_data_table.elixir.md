# Migração Elixir: Criar Tabela `bx_persons_data`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_data` no banco de dados SQLite. Esta tabela armazena os dados detalhados para perfis do tipo \"pessoa\", complementando as informações em `sys_accounts` e `sys_profiles`.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_persons_data_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxPersonsDataTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_data.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_data.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_data...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      author INTEGER NOT NULL,
      added INTEGER NOT NULL, -- Unix Timestamp
      changed INTEGER NOT NULL, -- Unix Timestamp
      picture INTEGER, -- FK para uma futura tabela de arquivos
      cover INTEGER, -- FK para uma futura tabela de arquivos
      fullname TEXT NOT NULL,
      last_name TEXT,
      description TEXT,
      gender TEXT,
      birthday TEXT, -- Formato 'YYYY-MM-DD'
      location TEXT,
      views INTEGER NOT NULL DEFAULT 0,
      rate REAL NOT NULL DEFAULT 0,
      votes INTEGER NOT NULL DEFAULT 0,
      score INTEGER NOT NULL DEFAULT 0,
      sc_up INTEGER NOT NULL DEFAULT 0,
      sc_down INTEGER NOT NULL DEFAULT 0,
      favorites INTEGER NOT NULL DEFAULT 0,
      comments INTEGER NOT NULL DEFAULT 0,
      reports INTEGER NOT NULL DEFAULT 0,
      featured INTEGER NOT NULL DEFAULT 0,
      allow_view_to TEXT NOT NULL DEFAULT '3',
      allow_post_to TEXT NOT NULL DEFAULT '5',
      allow_contact_to TEXT NOT NULL DEFAULT '3',
      settings TEXT -- JSON com configurações adicionais
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_data_author ON bx_persons_data(author);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_data_fullname ON bx_persons_data(fullname);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_data criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_data: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_data.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_data...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS bx_persons_data;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_data removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_data: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   A coluna `id` desta tabela será referenciada por `sys_profiles.content_id` quando `sys_profiles.type` for \"bx_persons\".
*   `author`: ID do perfil (de `sys_profiles.id`) que é o \"dono\" ou criador desta entrada de dados de pessoa.
*   `picture` e `cover`: Estes campos são planejados para armazenar IDs que referenciam entradas em uma futura tabela de gerenciamento de arquivos/imagens (ex: `sys_files`). Inicialmente, são apenas `INTEGER`.
*   `allow_view_to`, `allow_post_to`, `allow_contact_to`: Estes campos, no UNA original, referenciam IDs de grupos de privacidade. Na API \"Deeper\", a lógica para interpretar e aplicar essas regras de privacidade precisará ser implementada, possivelmente consultando uma futura tabela `sys_privacy_groups` ou simplificando o modelo de privacidade. Por enquanto, são armazenados como `TEXT`.
*   `settings`: Armazenado como `TEXT`, destinado a conter uma string JSON com configurações adicionais específicas do perfil.