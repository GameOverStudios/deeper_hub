defmodule DeeperHub.Core.Data.Migrations.SysRewriteRules do
  @moduledoc """
  Migration para criar e remover a tabela sys_rewrite_rules.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_rewrite_rules.
  """
  def up do
    Logger.info("Criando tabela de sys_rewrite_rules...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_rewrite_rules (
id int(10) unsigned NOT NULL  auto_increment,
preg varchar(255) NOT NULL,
service varchar(255) NOT NULL,
active tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_rewrite_rules criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_rewrite_rules: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_rewrite_rules.
  """
  def down do
    Logger.info("Removendo tabela de sys_rewrite_rules...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_rewrite_rules
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_rewrite_rules removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_rewrite_rules: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
