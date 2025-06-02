defmodule DeeperHub.Core.Data.Migrations.SysFormDisplayInputs do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_display_inputs.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_display_inputs.
  """
  def up do
    Logger.info("Criando tabela de sys_form_display_inputs...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_form_display_inputs (
id int(11) NOT NULL  auto_increment,
display_name varchar(64) NOT NULL,
input_name varchar(32) NOT NULL,
visible_for_levels int(11) NOT NULL DEFAULT 2147483647,
active tinyint(4) NOT NULL DEFAULT 0,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_display_inputs criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_display_inputs: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_display_inputs.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_display_inputs...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_display_inputs
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_display_inputs removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_display_inputs: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
