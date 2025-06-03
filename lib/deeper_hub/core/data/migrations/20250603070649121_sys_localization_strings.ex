defmodule DeeperHub.Core.Data.Migrations.SysLocalizationStrings do
  @moduledoc """
  Migration para criar e remover a tabela sys_localization_strings.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_localization_strings.
  """
  def up do
    Logger.info("Criando tabela de sys_localization_strings...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_localization_strings (
    IDKey INTEGER NOT NULL DEFAULT 0,
    IDLanguage INTEGER NOT NULL DEFAULT 0,
    String TEXT NOT NULL,
      PRIMARY KEY (IDKey, IDLanguage)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_localization_strings criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_localization_strings: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_localization_strings: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_localization_strings.
  """
  def down do
    Logger.info("Removendo tabela de sys_localization_strings...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_localization_strings
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_localization_strings removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_localization_strings: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_localization_strings: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
