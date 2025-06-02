defmodule DeeperHub.Core.Data.Migrations.SysFormDisplays do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_displays.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_displays.
  """
  def up do
    Logger.info("Criando tabela de sys_form_displays...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_form_displays (
id int(11) NOT NULL  auto_increment,
display_name varchar(64) NOT NULL,
module varchar(32) NOT NULL,
object varchar(64) NOT NULL,
title varchar(255) NOT NULL,
view_mode tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_displays criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_displays: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_displays.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_displays...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_displays
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_displays removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_displays: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
