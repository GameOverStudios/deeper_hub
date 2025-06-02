defmodule DeeperHub.Core.Data.Migrations.BxCoursesInvites do
  @moduledoc """
  Migration para criar e remover a tabela bx_courses_invites.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_courses_invites.
  """
  def up do
    Logger.info("Criando tabela de bx_courses_invites...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_courses_invites (
id int(11) NOT NULL  auto_increment,
key varchar(128) NOT NULL DEFAULT 0,
group_profile_id int(11) NOT NULL DEFAULT 0,
author_profile_id int(11) NOT NULL DEFAULT 0,
invited_profile_id int(11) NOT NULL DEFAULT 0,
added int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_invites criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_courses_invites: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_courses_invites.
  """
  def down do
    Logger.info("Removendo tabela de bx_courses_invites...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_courses_invites
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_invites removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_courses_invites: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
