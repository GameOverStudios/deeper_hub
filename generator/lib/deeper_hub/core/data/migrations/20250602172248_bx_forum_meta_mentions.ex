defmodule DeeperHub.Core.Data.Migrations.BxForumMetaMentions do
  @moduledoc """
  Migration para criar e remover a tabela bx_forum_meta_mentions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_forum_meta_mentions.
  """
  def up do
    Logger.info("Criando tabela de bx_forum_meta_mentions...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_forum_meta_mentions (
id int(11) NOT NULL  auto_increment,
object_id int(10) unsigned NOT NULL,
profile_id int(10) unsigned NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_meta_mentions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_forum_meta_mentions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_forum_meta_mentions.
  """
  def down do
    Logger.info("Removendo tabela de bx_forum_meta_mentions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_forum_meta_mentions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_forum_meta_mentions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_forum_meta_mentions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
