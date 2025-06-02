defmodule DeeperHub.Core.Data.Migrations.SysLocalizationLanguages do
  @moduledoc """
  Migration para criar e remover a tabela sys_localization_languages.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_localization_languages.
  """
  def up do
    Logger.info("Criando tabela de sys_localization_languages...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS sys_localization_languages (
ID int(10) unsigned NOT NULL  auto_increment,
Name varchar(5) NOT NULL DEFAULT,
Flag varchar(2) NOT NULL DEFAULT,
Title varchar(255) NOT NULL DEFAULT,
Direction enum('LTR','RTL') NOT NULL DEFAULT LTR,
LanguageCountry varchar(8) NOT NULL,
Enabled tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (ID)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_localization_languages criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_localization_languages: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_localization_languages.
  """
  def down do
    Logger.info("Removendo tabela de sys_localization_languages...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_localization_languages
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_localization_languages removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_localization_languages: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
