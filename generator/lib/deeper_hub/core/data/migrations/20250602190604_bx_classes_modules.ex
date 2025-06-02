defmodule DeeperHub.Core.Data.Migrations.BxClassesModules do
  @moduledoc """
  Migration para criar e remover a tabela bx_classes_modules.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_classes_modules.
  """
  def up do
    Logger.info("Criando tabela de bx_classes_modules...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_classes_modules (
id int(10) unsigned NOT NULL  auto_increment,
profile_id int(10) unsigned NOT NULL,
module_title varchar(255) NOT NULL,
author int(11) NOT NULL,
added int(11) NOT NULL,
changed int(11) NOT NULL,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_modules criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_classes_modules: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_classes_modules.
  """
  def down do
    Logger.info("Removendo tabela de bx_classes_modules...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_classes_modules
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_classes_modules removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_classes_modules: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
