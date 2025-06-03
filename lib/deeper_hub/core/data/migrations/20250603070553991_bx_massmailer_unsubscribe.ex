defmodule DeeperHub.Core.Data.Migrations.BxMassmailerUnsubscribe do
  @moduledoc """
  Migration para criar e remover a tabela bx_massmailer_unsubscribe.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_massmailer_unsubscribe.
  """
  def up do
    Logger.info("Criando tabela de bx_massmailer_unsubscribe...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_massmailer_unsubscribe (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NULL,
    campaign_id INTEGER NULL,
    unsubscribed INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_unsubscribe criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_unsubscribe: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_unsubscribe: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_massmailer_unsubscribe.
  """
  def down do
    Logger.info("Removendo tabela de bx_massmailer_unsubscribe...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_massmailer_unsubscribe
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_unsubscribe removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_unsubscribe: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_unsubscribe: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
