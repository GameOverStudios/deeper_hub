defmodule DeeperHub.Core.Data.Migrations.SysProfiles do
  @moduledoc """
  Migration para criar e remover a tabela sys_profiles.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_profiles.
  """
  def up do
    Logger.info("Criando tabela de sys_profiles...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_profiles (
id int(10) unsigned NOT NULL  auto_increment,
account_id int(10) unsigned NOT NULL,
type varchar(32) NOT NULL,
content_id int(10) unsigned NOT NULL,
cfw_value int(10) unsigned NOT NULL DEFAULT 2147483647,
cfw_items int(10) unsigned NOT NULL DEFAULT 2147483647,
cfu_items int(10) unsigned NOT NULL DEFAULT 2147483647,
cfu_locked tinyint(4) NOT NULL DEFAULT 0,
status enum('active','pending','suspended') NOT NULL DEFAULT active,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_profiles: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_profiles.
  """
  def down do
    Logger.info("Removendo tabela de sys_profiles...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_profiles
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_profiles removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_profiles: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
