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
id int(11) unsigned NOT NULL  auto_increment,
account_id int(11) NULL,
campaign_id int(11) NULL,
unsubscribed int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_massmailer_unsubscribe criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_massmailer_unsubscribe: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_massmailer_unsubscribe: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
