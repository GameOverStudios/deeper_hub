# Migração gerada com ID único: V1748745503936 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperForumTopicsTable do
  # Migração gerada com ID único: V1748745503936 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_forum_topics.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_forum_topics.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_forum_topics...", module: __MODULE__)

    # Similar à tabela de fóruns, first_post_id e last_post_id referenciam
    # deeper_forum_posts, que será criada depois.
    # Adotaremos a mesma estratégia de não definir a FK constraint no CREATE TABLE inicial.
    sql = """
    CREATE TABLE IF NOT EXISTS deeper_forum_topics (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      forum_id INTEGER NOT NULL,
      profile_id INTEGER NOT NULL, -- Autor do tópico
      title TEXT NOT NULL,
      slug TEXT NOT NULL,
      first_post_id INTEGER, -- Será FK para deeper_forum_posts.id
      views_count INTEGER NOT NULL DEFAULT 0,
      replies_count INTEGER NOT NULL DEFAULT 0,
      is_sticky INTEGER NOT NULL DEFAULT 0,
      is_locked INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'hidden_by_moderator', 'deleted_by_user')),
      last_post_id INTEGER, -- Será FK para deeper_forum_posts.id
      last_post_profile_id INTEGER, -- Será FK para sys_profiles.id
      last_post_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (forum_id) REFERENCES deeper_forums(id) ON DELETE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
      FOREIGN KEY (last_post_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
      UNIQUE (forum_id, slug)
    );

    CREATE INDEX IF NOT EXISTS idx_dft_forum_id_is_sticky_last_post_at ON deeper_forum_topics(forum_id, is_sticky DESC, last_post_at DESC);
    CREATE INDEX IF NOT EXISTS idx_dft_profile_id ON deeper_forum_topics(profile_id);
    CREATE INDEX IF NOT EXISTS idx_dft_last_post_at ON deeper_forum_topics(last_post_at DESC);
    -- O índice para (forum_id, slug) já é criado pela constraint UNIQUE.
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_forum_topics criada com sucesso.", module: __MODULE__)
        # Agora que deeper_forum_topics existe, poderíamos (numa migração separada ou aqui se a ordem estiver garantida)
        # tentar adicionar a FK em deeper_forums para last_topic_id.
        # Ex: Repo.execute("ALTER TABLE deeper_forums ADD CONSTRAINT fk_last_topic FOREIGN KEY (last_topic_id) REFERENCES deeper_forum_topics(id) ON DELETE SET NULL;")
        # No SQLite, ALTER TABLE para adicionar FKs é limitado. Geralmente envolve recriar a tabela.
        # Manteremos a integridade via aplicação por enquanto para estas FKs circulares/posteriores.
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_forum_topics: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_forum_topics.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_forum_topics...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_forum_topics;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_forum_topics removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_forum_topics: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end