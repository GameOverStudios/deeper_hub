defmodule DeeperHub.Core.Data.Migrations.BxGlossaryTerms do
  @moduledoc """
  Migration para criar e remover a tabela bx_glossary_terms.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_glossary_terms.
  """
  def up do
    Logger.info("Criando tabela de bx_glossary_terms...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_glossary_terms (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL,
    changed INTEGER NOT NULL,
    thumb INTEGER NOT NULL,
    title TEXT NOT NULL,
    cat INTEGER NOT NULL,
    text TEXT NOT NULL,
    labels TEXT NOT NULL,
    views INTEGER NOT NULL DEFAULT 0,
    rate REAL NOT NULL DEFAULT 0,
    votes INTEGER NOT NULL DEFAULT 0,
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
    status TEXT NOT NULL DEFAULT 'active',
    status_admin TEXT NOT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_glossary_terms criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_glossary_terms: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_glossary_terms: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_glossary_terms.
  """
  def down do
    Logger.info("Removendo tabela de bx_glossary_terms...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_glossary_terms
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_glossary_terms removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_glossary_terms: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_glossary_terms: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
