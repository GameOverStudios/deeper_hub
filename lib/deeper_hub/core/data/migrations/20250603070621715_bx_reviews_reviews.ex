defmodule DeeperHub.Core.Data.Migrations.BxReviewsReviews do
  @moduledoc """
  Migration para criar e remover a tabela bx_reviews_reviews.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_reviews_reviews.
  """
  def up do
    Logger.info("Criando tabela de bx_reviews_reviews...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_reviews_reviews (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL,
    changed INTEGER NOT NULL,
    thumb INTEGER NOT NULL,
    title TEXT NOT NULL,
    voting_options TEXT NOT NULL,
    voting_avg REAL NOT NULL,
    cat INTEGER NOT NULL,
    multicat TEXT NOT NULL,
    text TEXT NOT NULL,
    labels TEXT NOT NULL,
    location TEXT NOT NULL,
    views INTEGER NOT NULL DEFAULT 0,
    rate REAL NOT NULL DEFAULT 0,
    votes INTEGER NOT NULL DEFAULT 0,
    srate REAL NOT NULL DEFAULT 0,
    svotes INTEGER NOT NULL DEFAULT 0,
    rrate REAL NOT NULL DEFAULT 0,
    rvotes INTEGER NOT NULL DEFAULT 0,
    score INTEGER NOT NULL DEFAULT 0,
    sc_up INTEGER NOT NULL DEFAULT 0,
    sc_down INTEGER NOT NULL DEFAULT 0,
    favorites INTEGER NOT NULL DEFAULT 0,
    comments INTEGER NOT NULL DEFAULT 0,
    reports INTEGER NOT NULL DEFAULT 0,
    featured INTEGER NOT NULL DEFAULT 0,
    cf INTEGER NOT NULL DEFAULT 1,
    allow_view_to TEXT NOT NULL DEFAULT 3,
    reviewed_profile INTEGER NOT NULL DEFAULT 0,
    product TEXT NOT NULL,
    allow_comments INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'active',
    status_admin TEXT NOT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reviews_reviews criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_reviews_reviews: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_reviews_reviews: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_reviews_reviews.
  """
  def down do
    Logger.info("Removendo tabela de bx_reviews_reviews...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_reviews_reviews
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_reviews_reviews removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_reviews_reviews: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_reviews_reviews: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
