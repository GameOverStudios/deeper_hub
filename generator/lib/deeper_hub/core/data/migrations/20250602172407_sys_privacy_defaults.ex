defmodule DeeperHub.Core.Data.Migrations.SysPrivacyDefaults do
  @moduledoc """
  Migration para criar e remover a tabela sys_privacy_defaults.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_privacy_defaults.
  """
  def up do
    Logger.info("Criando tabela de sys_privacy_defaults...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_privacy_defaults (
owner_id int(11) NOT NULL DEFAULT 0,
action_id int(11) NOT NULL DEFAULT 0,
group_id int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (owner_id),
  PRIMARY KEY (action_id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_privacy_defaults criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_privacy_defaults: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_privacy_defaults.
  """
  def down do
    Logger.info("Removendo tabela de sys_privacy_defaults...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_privacy_defaults
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_privacy_defaults removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_privacy_defaults: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
