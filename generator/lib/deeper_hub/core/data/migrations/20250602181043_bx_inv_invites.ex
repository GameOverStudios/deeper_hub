defmodule DeeperHub.Core.Data.Migrations.BxInvInvites do
  @moduledoc """
  Migration para criar e remover a tabela bx_inv_invites.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_inv_invites.
  """
  def up do
    Logger.info("Criando tabela de bx_inv_invites...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_inv_invites (
id int(11) NOT NULL  auto_increment,
account_id int(11) NOT NULL,
profile_id int(11) NOT NULL,
key varchar(128) NOT NULL,
redirect varchar(255) NOT NULL DEFAULT,
email varchar(128) NOT NULL,
date int(11) NOT NULL DEFAULT 0,
date_seen int(11) NULL,
date_joined int(11) NULL,
joined_account_id int(11) NULL,
request_id int(11) NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_inv_invites criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_inv_invites: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_inv_invites.
  """
  def down do
    Logger.info("Removendo tabela de bx_inv_invites...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_inv_invites
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_inv_invites removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_inv_invites: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
