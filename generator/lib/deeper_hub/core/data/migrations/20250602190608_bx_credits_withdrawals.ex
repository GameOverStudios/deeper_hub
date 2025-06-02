defmodule DeeperHub.Core.Data.Migrations.BxCreditsWithdrawals do
  @moduledoc """
  Migration para criar e remover a tabela bx_credits_withdrawals.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_credits_withdrawals.
  """
  def up do
    Logger.info("Criando tabela de bx_credits_withdrawals...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_credits_withdrawals (
id int(11) unsigned NOT NULL  auto_increment,
performer_id int(11) unsigned NOT NULL DEFAULT 0,
profile_id int(11) unsigned NOT NULL DEFAULT 0,
amount float NOT NULL DEFAULT 0,
rate float NOT NULL DEFAULT 0,
message text NOT NULL DEFAULT '',
order varchar(32) NOT NULL DEFAULT,
added int(11) unsigned NOT NULL DEFAULT 0,
confirmed int(11) unsigned NOT NULL DEFAULT 0,
status enum('requested','canceled','confirmed') NOT NULL DEFAULT requested,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_withdrawals criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_credits_withdrawals: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_credits_withdrawals.
  """
  def down do
    Logger.info("Removendo tabela de bx_credits_withdrawals...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_credits_withdrawals
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_withdrawals removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_credits_withdrawals: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
