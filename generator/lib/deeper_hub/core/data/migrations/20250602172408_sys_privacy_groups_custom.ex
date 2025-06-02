defmodule DeeperHub.Core.Data.Migrations.SysPrivacyGroupsCustom do
  @moduledoc """
  Migration para criar e remover a tabela sys_privacy_groups_custom.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_privacy_groups_custom.
  """
  def up do
    Logger.info("Criando tabela de sys_privacy_groups_custom...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_privacy_groups_custom (
id int(11) unsigned NOT NULL  auto_increment,
profile_id int(11) NOT NULL DEFAULT 0,
content_id int(11) NOT NULL DEFAULT 0,
object varchar(64) NOT NULL DEFAULT,
group_id int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_privacy_groups_custom criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_privacy_groups_custom: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_privacy_groups_custom.
  """
  def down do
    Logger.info("Removendo tabela de sys_privacy_groups_custom...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_privacy_groups_custom
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_privacy_groups_custom removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_privacy_groups_custom: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
