defmodule DeeperHub.Core.Data.Migrations.BxReviewsVotingOptions do
  @moduledoc """
  Migration para criar e remover a tabela bx_reviews_voting_options.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reviews_voting_options.
  """
  def up do
    Logger.info("Criando tabela de bx_reviews_voting_options...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_reviews_voting_options (
id int(10) unsigned NOT NULL  auto_increment,
lkey varchar(255) NOT NULL DEFAULT,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reviews_voting_options criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reviews_voting_options: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reviews_voting_options.
  """
  def down do
    Logger.info("Removendo tabela de bx_reviews_voting_options...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reviews_voting_options
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reviews_voting_options removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reviews_voting_options: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
