defmodule DeeperHub.Core.Data.Migrations.BxPollsSubentries do
  @moduledoc """
  Migration para criar e remover a tabela bx_polls_subentries.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_polls_subentries.
  """
  def up do
    Logger.info("Criando tabela de bx_polls_subentries...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_polls_subentries (
id int(10) unsigned NOT NULL  auto_increment,
entry_id int(11) unsigned NOT NULL DEFAULT 0,
title varchar(255) NOT NULL,
rate float NOT NULL DEFAULT 0,
votes int(11) NOT NULL DEFAULT 0,
order int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_polls_subentries criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_polls_subentries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_polls_subentries.
  """
  def down do
    Logger.info("Removendo tabela de bx_polls_subentries...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_polls_subentries
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_polls_subentries removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_polls_subentries: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
