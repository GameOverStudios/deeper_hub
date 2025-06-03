defmodule DeeperHub.Core.Data.Migrations.SysObjectsCaptcha do
  @moduledoc """
  Migration para criar e remover a tabela sys_objects_captcha.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_objects_captcha.
  """
  def up do
    Logger.info("Criando tabela de sys_objects_captcha...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_captcha (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    title TEXT NOT NULL,
    override_class_name TEXT NOT NULL,
    override_class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_captcha criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_objects_captcha: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_objects_captcha: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_objects_captcha.
  """
  def down do
    Logger.info("Removendo tabela de sys_objects_captcha...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_objects_captcha
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_objects_captcha removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_objects_captcha: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_objects_captcha: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
