defmodule DeeperHub.Core.Data.Migrations.BxFdbAnswers2users do
  @moduledoc """
  Migration para criar e remover a tabela bx_fdb_answers2users.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_fdb_answers2users.
  """
  def up do
    Logger.info("Criando tabela de bx_fdb_answers2users...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_fdb_answers2users (
id int(11) unsigned NOT NULL  auto_increment,
answer_id int(11) unsigned NOT NULL DEFAULT 0,
profile_id int(11) unsigned NOT NULL DEFAULT 0,
text varchar(255) NOT NULL DEFAULT,
added int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_fdb_answers2users criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_fdb_answers2users: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_fdb_answers2users.
  """
  def down do
    Logger.info("Removendo tabela de bx_fdb_answers2users...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_fdb_answers2users
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_fdb_answers2users removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_fdb_answers2users: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
