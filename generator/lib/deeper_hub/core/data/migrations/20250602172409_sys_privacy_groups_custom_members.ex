defmodule DeeperHub.Core.Data.Migrations.SysPrivacyGroupsCustomMembers do
  @moduledoc """
  Migration para criar e remover a tabela sys_privacy_groups_custom_members.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_privacy_groups_custom_members.
  """
  def up do
    Logger.info("Criando tabela de sys_privacy_groups_custom_members...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_privacy_groups_custom_members (
group_id int(11) NOT NULL DEFAULT 0,
member_id int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (group_id),
  PRIMARY KEY (member_id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_privacy_groups_custom_members criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_privacy_groups_custom_members: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_privacy_groups_custom_members.
  """
  def down do
    Logger.info("Removendo tabela de sys_privacy_groups_custom_members...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_privacy_groups_custom_members
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_privacy_groups_custom_members removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_privacy_groups_custom_members: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
