defmodule DeeperHub.Core.Data.Migrations.SysFormPreValues do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_pre_values.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_pre_values.
  """
  def up do
    Logger.info("Criando tabela de sys_form_pre_values...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_form_pre_values (
id int(11) NOT NULL  auto_increment,
Key varchar(255) NOT NULL DEFAULT,
Value varchar(255) NOT NULL DEFAULT,
Order int(10) unsigned NOT NULL DEFAULT 0,
LKey varchar(255) NOT NULL DEFAULT,
LKey2 varchar(255) NOT NULL DEFAULT,
Data text NOT NULL DEFAULT '',
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_pre_values criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_pre_values: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_pre_values.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_pre_values...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_pre_values
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_pre_values removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_pre_values: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
