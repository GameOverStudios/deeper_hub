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
    ID INTEGER NOT NULL,
    Name TEXT NOT NULL,
    Flag TEXT NOT NULL,
    Title TEXT NOT NULL,
    Direction TEXT NOT NULL DEFAULT 'LTR',
    LanguageCountry TEXT NOT NULL,
    Enabled INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_localization_languages criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_localization_languages: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_localization_languages: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_localization_languages: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_localization_languages: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
