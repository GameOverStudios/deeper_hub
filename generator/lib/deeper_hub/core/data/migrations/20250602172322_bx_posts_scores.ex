defmodule DeeperHub.Core.Data.Migrations.BxPostsScores do
  @moduledoc """
  Migration para criar e remover a tabela bx_posts_scores.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_posts_scores.
  """
  def up do
    Logger.info("Criando tabela de bx_posts_scores...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_posts_scores (
id int(11) NOT NULL  auto_increment,
object_id int(11) NOT NULL DEFAULT 0,
count_up int(11) NOT NULL DEFAULT 0,
count_down int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_posts_scores criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_posts_scores: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_posts_scores.
  """
  def down do
    Logger.info("Removendo tabela de bx_posts_scores...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_posts_scores
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_posts_scores removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_posts_scores: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
