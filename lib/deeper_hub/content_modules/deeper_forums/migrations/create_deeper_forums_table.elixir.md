# Migração Elixir: Criar Tabela `deeper_forums`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_forums` no banco de dados SQLite. Esta tabela armazena os fóruns de discussão principais, que por sua vez conterão tópicos.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_forums_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperForumsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_forums.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_forums.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_forums...\", module: __MODULE__)

    # Nota: As FKs para last_topic_id, last_post_id, last_post_profile_id
    # apontam para tabelas que serão criadas depois.
    # No SQLite, as FKs são verificadas apenas quando habilitadas (PRAGMA foreign_keys = ON).
    # Se as tabelas referenciadas não existirem no momento da criação desta tabela
    # e as FKs estiverem habilitadas, pode haver um erro.
    # Uma estratégia é criar tabelas sem FKs inicialmente e adicioná-las depois,
    # ou garantir a ordem de criação e que as FKs sejam \"deferrable\" se o SQLite
    # suportar isso de forma que funcione com DDL.
    # Para simplificar aqui, assumimos que a ordem das migrações lidará com isso,
    # ou que as FKs para estas colunas de \"último post/tópico\" podem ser adicionadas
    # numa migração separada após todas as tabelas base existirem, ou serem nullable e
    # a integridade gerenciada pela aplicação.
    # Vamos defini-las como nullable e sem constraints de FK diretas nesta migração inicial
    # para evitar problemas de ordem, e a aplicação garantirá a integridade dos IDs.
    # As FKs para tabelas já existentes (categories, profiles) podem ser mantidas.

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_forums (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER,
      title TEXT NOT NULL UNIQUE,
      slug TEXT NOT NULL UNIQUE,
      description TEXT,
      order_index INTEGER NOT NULL DEFAULT 0,
      topics_count INTEGER NOT NULL DEFAULT 0,
      posts_count INTEGER NOT NULL DEFAULT 0,
      last_topic_id INTEGER, -- Será FK para deeper_forum_topics.id
      last_post_id INTEGER,  -- Será FK para deeper_forum_posts.id
      last_post_profile_id INTEGER, -- Será FK para sys_profiles.id
      last_post_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (category_id) REFERENCES deeper_forum_categories(id) ON DELETE SET NULL,
      FOREIGN KEY (last_post_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL
      -- FKs para last_topic_id e last_post_id serão idealmente adicionadas após suas tabelas existirem
      -- ou gerenciadas pela aplicação.
    );

    CREATE INDEX IF NOT EXISTS idx_df_slug ON deeper_forums(slug);
    CREATE INDEX IF NOT EXISTS idx_df_category_id ON deeper_forums(category_id);
    CREATE INDEX IF NOT EXISTS idx_df_order_index_title ON deeper_forums(order_index, title);
    CREATE INDEX IF NOT EXISTS idx_df_last_post_at ON deeper_forums(last_post_at DESC);
    \"\"\"
    # Adicionar constraints de FK para last_topic_id e last_post_id via ALTER TABLE
    # em uma migração posterior ou garantir que a lógica da aplicação mantenha a integridade
    # se as tabelas forem criadas em uma ordem que não permita FKs imediatas.
    # A forma mais segura é criar a tabela e depois usar ALTER TABLE ADD COLUMN com a FK,
    # ou ALTER TABLE (que no SQLite para adicionar FKs pode ser recriar a tabela).
    # Para esta etapa, manteremos simples.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_forums criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_forums: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_forums.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_forums...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_forums;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_forums removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_forums: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Depende da existência de `deeper_forum_categories` (para `category_id`) e `sys_profiles` (para `last_post_profile_id`).
*   **Chaves Estrangeiras Cíclicas/Posteriores:** As colunas `last_topic_id` (referenciando `deeper_forum_topics`) e `last_post_id` (referenciando `deeper_forum_posts`) criam uma dependência com tabelas que serão definidas *depois* desta.
    *   **Estratégia Adotada Aqui:** As colunas são criadas sem a `FOREIGN KEY` constraint explícita no `CREATE TABLE` inicial para evitar erros de ordem de criação. A integridade desses IDs será mantida pela lógica da aplicação ou as constraints FK podem ser adicionadas numa migração posterior usando `ALTER TABLE` (que no SQLite para adicionar FKs pode ser complexo, muitas vezes envolvendo recriar a tabela).
    *   Uma alternativa seria tornar essas colunas `NULLABLE` e a aplicação garante que os IDs sejam válidos.
    *   Se o sistema de migração permitir, marcar as FKs como `DEFERRABLE INITIALLY DEFERRED` poderia ser uma solução, mas isso depende do suporte do driver SQLite e da biblioteca de migração.
*   As contagens (`topics_count`, `posts_count`) e os campos `last_post_*` são denormalizados e precisarão ser atualizados pela lógica da aplicação quando novos tópicos/posts forem criados ou excluídos.