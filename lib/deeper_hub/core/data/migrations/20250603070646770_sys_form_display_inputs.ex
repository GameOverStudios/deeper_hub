defmodule DeeperHub.Core.Data.Migrations.SysFormDisplayInputs do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_display_inputs.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_display_inputs.
  """
  def up do
    Logger.info("Criando tabela de sys_form_display_inputs...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_form_display_inputs (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    display_name TEXT NOT NULL,
    input_name TEXT NOT NULL,
    visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
    active INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_display_inputs criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_form_display_inputs: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_display_inputs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_display_inputs.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_display_inputs...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_display_inputs
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_display_inputs removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_form_display_inputs: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_display_inputs: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
