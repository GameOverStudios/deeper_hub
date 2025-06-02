defmodule DeeperHub.Core.Data.Migrations.SysFormInputsPrivacy do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_inputs_privacy.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_inputs_privacy.
  """
  def up do
    Logger.info("Criando tabela de sys_form_inputs_privacy...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_form_inputs_privacy (
id int(11) NOT NULL  auto_increment,
input_id int(11) unsigned NOT NULL DEFAULT 0,
author_id int(11) unsigned NOT NULL DEFAULT 0,
allow_view_to varchar(16) NOT NULL DEFAULT 3,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_inputs_privacy criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_inputs_privacy: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_inputs_privacy.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_inputs_privacy...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_inputs_privacy
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_inputs_privacy removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_inputs_privacy: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
