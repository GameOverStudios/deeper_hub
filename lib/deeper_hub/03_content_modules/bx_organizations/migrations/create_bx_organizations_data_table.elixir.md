# Migração Elixir: Criar Tabela `bx_organizations_data`

Este módulo de migração Elixir é responsável por criar a tabela `bx_organizations_data` no banco de dados SQLite. Esta tabela armazena os dados detalhados para perfis do tipo \"Organização\".

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_organizations_data_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxOrganizationsDataTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_organizations_data.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_organizations_data.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_organizations_data...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_organizations_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      author_id INTEGER NOT NULL,
      org_name TEXT NOT NULL,
      org_uri TEXT NOT NULL UNIQUE,
      org_cat INTEGER,
      org_desc TEXT,
      org_logo INTEGER,
      org_cover INTEGER,
      org_website TEXT,
      org_email TEXT,
      org_phone TEXT,
      org_address_street TEXT,
      org_address_city TEXT,
      org_address_state TEXT,
      org_address_zip TEXT,
      org_address_country TEXT,
      org_location_lat REAL,
      org_location_lng REAL,
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'pending', 'hidden')),
      status_admin TEXT NOT NULL DEFAULT 'active' CHECK(status_admin IN ('active', 'hidden', 'pending')),
      allow_view_to TEXT NOT NULL DEFAULT '3',
      allow_post_to TEXT NOT NULL DEFAULT 'c',
      allow_contact_to TEXT NOT NULL DEFAULT 'c',
      views INTEGER NOT NULL DEFAULT 0,
      fans_count INTEGER NOT NULL DEFAULT 0,
      comments_count INTEGER NOT NULL DEFAULT 0,
      reports_count INTEGER NOT NULL DEFAULT 0,
      featured_until INTEGER,
      added INTEGER NOT NULL, -- Unix Timestamp
      changed INTEGER NOT NULL, -- Unix Timestamp
      settings TEXT,

      FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
      -- FOREIGN KEY (org_cat) REFERENCES bx_organizations_categories(id) ON DELETE SET NULL,
      -- FOREIGN KEY (org_logo) REFERENCES deeper_files(id) ON DELETE SET NULL,
      -- FOREIGN KEY (org_cover) REFERENCES deeper_files(id) ON DELETE SET NULL
    );

    CREATE INDEX IF NOT EXISTS idx_bx_organizations_data_author_id ON bx_organizations_data(author_id);
    CREATE UNIQUE INDEX IF NOT EXISTS idx_bx_organizations_data_org_uri ON bx_organizations_data(org_uri);
    CREATE INDEX IF NOT EXISTS idx_bx_organizations_data_org_name ON bx_organizations_data(org_name);
    CREATE INDEX IF NOT EXISTS idx_bx_organizations_data_org_cat ON bx_organizations_data(org_cat);
    CREATE INDEX IF NOT EXISTS idx_bx_organizations_data_status ON bx_organizations_data(status);
    \"\"\"

    # Notas sobre FKs comentadas:
    # - A FK para 'org_cat' depende da criação da tabela 'bx_organizations_categories'.
    # - As FKs para 'org_logo' e 'org_cover' dependem da criação da tabela 'deeper_files' (do módulo 06_file_management).
    # Elas podem ser adicionadas em migrações separadas (\"ALTER TABLE\") após a criação das tabelas referenciadas,
    # ou a tabela pode ser criada sem elas inicialmente se as tabelas referenciadas não existirem ainda.
    # Para SQLite, é mais limpo definir FKs na criação se possível, implicando uma ordem correta de migrações.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_organizations_data criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_organizations_data: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_organizations_data.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_organizations_data...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS bx_organizations_data;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_organizations_data removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_organizations_data: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```