defmodule DeeperHub.Core.Data.Migrations.BxCoursesAdmins do
  @moduledoc """
  Migration para criar e remover a tabela bx_courses_admins.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_courses_admins.
  """
  def up do
    Logger.info("Criando tabela de bx_courses_admins...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_courses_admins (
id int(11) NOT NULL  auto_increment,
group_profile_id int(10) unsigned NOT NULL,
fan_id int(10) unsigned NOT NULL,
role int(10) unsigned NOT NULL DEFAULT 0,
order varchar(32) NOT NULL DEFAULT,
added int(11) unsigned NOT NULL DEFAULT 0,
expired int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_admins criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_courses_admins: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_courses_admins.
  """
  def down do
    Logger.info("Removendo tabela de bx_courses_admins...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_courses_admins
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_courses_admins removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_courses_admins: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
