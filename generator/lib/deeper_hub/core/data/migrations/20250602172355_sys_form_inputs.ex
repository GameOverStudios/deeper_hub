defmodule DeeperHub.Core.Data.Migrations.SysFormInputs do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_inputs.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_inputs.
  """
  def up do
    Logger.info("Criando tabela de sys_form_inputs...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_form_inputs (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
module varchar(32) NOT NULL,
name varchar(255) NOT NULL,
value varchar(255) NOT NULL,
values text NOT NULL,
checked tinyint(4) NOT NULL DEFAULT 0,
type varchar(32) NOT NULL,
caption_system varchar(255) NOT NULL,
caption varchar(255) NOT NULL,
info varchar(255) NOT NULL,
help varchar(255) NOT NULL,
icon text NOT NULL,
required tinyint(4) NOT NULL DEFAULT 0,
unique tinyint(4) NOT NULL DEFAULT 0,
collapsed tinyint(4) NOT NULL DEFAULT 0,
html tinyint(4) NOT NULL DEFAULT 0,
privacy tinyint(4) NOT NULL DEFAULT 0,
rateable varchar(32) NOT NULL DEFAULT,
attrs text NOT NULL,
attrs_tr text NOT NULL,
attrs_wrapper text NOT NULL,
checker_func varchar(32) NOT NULL,
checker_params text NOT NULL,
checker_error varchar(255) NOT NULL,
db_pass varchar(32) NOT NULL,
db_params text NOT NULL,
editable tinyint(4) NOT NULL DEFAULT 1,
deletable tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_inputs criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_inputs: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_inputs.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_inputs...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_inputs
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_inputs removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_inputs: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
