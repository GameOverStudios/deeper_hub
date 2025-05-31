# Migração Elixir: Criar Tabela `deeper_group_content_posts`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_group_content_posts` no banco de dados SQLite. Esta tabela serve como um exemplo para armazenar posts ou discussões específicas dentro de um grupo.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_group_content_posts_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperGroupContentPostsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_group_content_posts.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_group_content_posts.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_group_content_posts...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_group_content_posts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL,
      profile_id INTEGER NOT NULL,
      parent_post_id INTEGER,
      body TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (group_id) REFERENCES deeper_groups(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (parent_post_id) REFERENCES deeper_group_content_posts(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dgcp_group_id_created_at ON deeper_group_content_posts(group_id, created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_dgcp_profile_id ON deeper_group_content_posts(profile_id);
    CREATE INDEX IF NOT EXISTS idx_dgcp_parent_post_id ON deeper_group_content_posts(parent_post_id);
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_group_content_posts criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_group_content_posts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_group_content_posts.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_group_content_posts...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_group_content_posts;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_group_content_posts removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_group_content_posts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela depende da existência de `deeper_groups` e `sys_profiles`.
*   `parent_post_id` permite posts aninhados ou um sistema de comentários simples para os posts do grupo, referenciando a própria tabela.
*   `ON DELETE CASCADE` para `group_id`, `profile_id`, e `parent_post_id` garante que os posts e seus sub-posts sejam limpos se o grupo, o autor do post, ou o post pai forem excluídos.
*   Interações como votos ou reações para estes posts de grupo seriam gerenciadas pelos sistemas genéricos de interação (`sys_objects_vote`, etc.), usando um `object_name` como \"deeper_group_posts\" e o `id` deste post como `object_id`.