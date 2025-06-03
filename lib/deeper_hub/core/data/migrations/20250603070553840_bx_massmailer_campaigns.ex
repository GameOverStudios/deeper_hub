defmodule DeeperHub.Core.Data.Migrations.BxMassmailerCampaigns do
  @moduledoc """
  Migration para criar e remover a tabela bx_massmailer_campaigns.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_massmailer_campaigns.
  """
  def up do
    Logger.info("Criando tabela de bx_massmailer_campaigns...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_massmailer_campaigns (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    title TEXT NULL,
    subject TEXT NULL,
    from_name TEXT NULL,
    reply_to TEXT NULL,
    body TEXT NULL,
    segments TEXT NULL,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL DEFAULT 0,
    changed INTEGER NOT NULL DEFAULT 0,
    date_sent INTEGER NOT NULL DEFAULT 0,
    email_list TEXT NULL,
    is_one_per_account INTEGER NOT NULL,
    is_track_links INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_campaigns criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_campaigns: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_campaigns: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_massmailer_campaigns.
  """
  def down do
    Logger.info("Removendo tabela de bx_massmailer_campaigns...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_massmailer_campaigns
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_campaigns removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_campaigns: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_campaigns: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
