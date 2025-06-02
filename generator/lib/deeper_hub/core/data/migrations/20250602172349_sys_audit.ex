defmodule DeeperHub.Core.Data.Migrations.SysAudit do
  @moduledoc """
  Migration para criar e remover a tabela sys_audit.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_audit.
  """
  def up do
    Logger.info("Criando tabela de sys_audit...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_audit (
id int(11) unsigned NOT NULL  auto_increment,
added int(11) NOT NULL,
profile_id int(10) NOT NULL,
profile_title varchar(255) NOT NULL,
content_id int(10) NOT NULL,
content_title varchar(255) NOT NULL,
content_module varchar(32) NOT NULL DEFAULT,
content_info_object varchar(32) NOT NULL DEFAULT,
context_profile_id int(10) NOT NULL,
context_profile_title varchar(255) NOT NULL,
action_lang_key varchar(255) NOT NULL,
action_lang_key_params text NOT NULL,
extras text NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_audit criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_audit: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_audit.
  """
  def down do
    Logger.info("Removendo tabela de sys_audit...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_audit
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_audit removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_audit: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
