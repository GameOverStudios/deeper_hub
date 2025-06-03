defmodule DeeperHub.Core.Data.Migrations.BxMassmailerLinks do
  @moduledoc """
  Migration para criar e remover a tabela bx_massmailer_links.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_massmailer_links.
  """
  def up do
    Logger.info("Criando tabela de bx_massmailer_links...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_massmailer_links (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    letter_hash TEXT NULL,
    hash TEXT NULL,
    link TEXT NULL,
    title TEXT NULL,
    campaign_id INTEGER NULL,
    date_click INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_links criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_links: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_links: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_massmailer_links.
  """
  def down do
    Logger.info("Removendo tabela de bx_massmailer_links...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_massmailer_links
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_links removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_links: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_links: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
