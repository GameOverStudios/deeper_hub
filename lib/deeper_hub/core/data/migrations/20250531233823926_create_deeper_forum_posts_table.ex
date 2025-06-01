# Migração gerada com ID único: V1748745503926 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperForumPostsTable do
  # Migração gerada com ID único: V1748745503926 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_forum_posts.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_forum_posts.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_forum_posts...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_forum_posts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      topic_id INTEGER NOT NULL,
      profile_id INTEGER NOT NULL, -- Autor do post
      parent_post_id INTEGER, -- Para respostas aninhadas ou citações
      body TEXT NOT NULL,
      ip_address TEXT,
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'hidden_by_moderator', 'deleted_by_user')),
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL, -- Timestamp da última edição do post em si
      edited_at INTEGER, -- Timestamp da última edição (pode ser o mesmo que updated_at)
      edited_by_profile_id INTEGER,
      FOREIGN KEY (topic_id) REFERENCES deeper_forum_topics(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
      FOREIGN KEY (parent_post_id) REFERENCES deeper_forum_posts(id) ON DELETE SET NULL, -- Ou CASCADE se respostas devem ser deletadas com o pai
      FOREIGN KEY (edited_by_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL
    );

    CREATE INDEX IF NOT EXISTS idx_dfp_topic_id_created_at ON deeper_forum_posts(topic_id, created_at ASC);
    CREATE INDEX IF NOT EXISTS idx_dfp_profile_id ON deeper_forum_posts(profile_id);
    CREATE INDEX IF NOT EXISTS idx_dfp_parent_post_id ON deeper_forum_posts(parent_post_id);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_forum_posts criada com sucesso.", module: __MODULE__)
        # Agora que deeper_forum_posts existe, as FKs em deeper_forums e deeper_forum_topics
        # para last_post_id e first_post_id poderiam ser teoricamente adicionadas/validadas.
        # No entanto, devido às limitações do ALTER TABLE do SQLite para adicionar FKs,
        # essa integridade é melhor gerenciada pela aplicação ou as tabelas recriadas com as FKs
        # em uma ordem específica se o esquema for totalmente novo.
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_forum_posts: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_forum_posts.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_forum_posts...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_forum_posts;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_forum_posts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_forum_posts: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
