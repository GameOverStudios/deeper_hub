defmodule DeeperHub.Core.Data.Migrations.SysAgentsProviderOptions do
  @moduledoc """
  Migration para criar e remover a tabela sys_agents_provider_options.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_agents_provider_options.
  """
  def up do
    Logger.info("Criando tabela de sys_agents_provider_options...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_agents_provider_options (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    provider_type_id INTEGER NOT NULL DEFAULT 0,
    name TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'text',
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '''',
    extra TEXT NOT NULL,
    check_type TEXT NOT NULL,
    check_params TEXT NOT NULL,
    check_error TEXT NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_provider_options criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_agents_provider_options: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_agents_provider_options: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_agents_provider_options.
  """
  def down do
    Logger.info("Removendo tabela de sys_agents_provider_options...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_agents_provider_options
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_agents_provider_options removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_agents_provider_options: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_agents_provider_options: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
