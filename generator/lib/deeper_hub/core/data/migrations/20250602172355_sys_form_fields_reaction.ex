defmodule DeeperHub.Core.Data.Migrations.SysFormFieldsReaction do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_fields_reaction.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_fields_reaction.
  """
  def up do
    Logger.info("Criando tabela de sys_form_fields_reaction...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_form_fields_reaction (
id int(11) NOT NULL  auto_increment,
object_id int(11) NOT NULL DEFAULT 0,
reaction varchar(32) NOT NULL DEFAULT,
count int(11) NOT NULL DEFAULT 0,
sum int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_fields_reaction criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_fields_reaction: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_fields_reaction.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_fields_reaction...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_fields_reaction
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_fields_reaction removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_fields_reaction: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
