defmodule DeeperHub.Core.Data.Migrations.BxMassmailerLetters do
  @moduledoc """
  Migration para criar e remover a tabela bx_massmailer_letters.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_massmailer_letters.
  """
  def up do
    Logger.info("Criando tabela de bx_massmailer_letters...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_massmailer_letters (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    campaign_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    date_sent INTEGER NOT NULL DEFAULT 0,
    date_seen INTEGER NOT NULL DEFAULT 0,
    date_click INTEGER NOT NULL DEFAULT 0,
    hash TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_letters criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_letters: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_letters: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_massmailer_letters.
  """
  def down do
    Logger.info("Removendo tabela de bx_massmailer_letters...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_massmailer_letters
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_letters removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_letters: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_letters: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
