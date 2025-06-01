# Migração gerada com ID único: V1748745503929 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateDeeperForumReadTopicsTable do
  # Migração gerada com ID único: V1748745503929 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela deeper_forum_read_topics.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela deeper_forum_read_topics.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela deeper_forum_read_topics...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS deeper_forum_read_topics (
      profile_id INTEGER NOT NULL,
      topic_id INTEGER NOT NULL,
      last_read_post_id INTEGER NOT NULL,
      last_read_at INTEGER NOT NULL,
      PRIMARY KEY (profile_id, topic_id),
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (topic_id) REFERENCES deeper_forum_topics(id) ON DELETE CASCADE,
      FOREIGN KEY (last_read_post_id) REFERENCES deeper_forum_posts(id) ON DELETE CASCADE
    );
    """
    # Não são necessários índices adicionais além da chave primária composta,
    # a menos que haja queries específicas que não a utilizem bem.

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_forum_read_topics criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela deeper_forum_read_topics: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela deeper_forum_read_topics.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela deeper_forum_read_topics...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS deeper_forum_read_topics;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela deeper_forum_read_topics removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela deeper_forum_read_topics: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end