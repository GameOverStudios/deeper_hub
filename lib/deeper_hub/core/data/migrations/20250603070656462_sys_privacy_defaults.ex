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
    owner_id INTEGER NOT NULL DEFAULT 0,
    action_id INTEGER NOT NULL DEFAULT 0,
    group_id INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (owner_id, action_id)
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_privacy_defaults criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_privacy_defaults: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_privacy_defaults: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_privacy_defaults: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_privacy_defaults: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
