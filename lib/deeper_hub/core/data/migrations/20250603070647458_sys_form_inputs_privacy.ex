defmodule DeeperHub.Core.Data.Migrations.SysFormInputsPrivacy do
  @moduledoc """
  Migration para criar e remover a tabela sys_form_inputs_privacy.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_form_inputs_privacy.
  """
  def up do
    Logger.info("Criando tabela de sys_form_inputs_privacy...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_form_inputs_privacy (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    input_id INTEGER NOT NULL DEFAULT 0,
    author_id INTEGER NOT NULL DEFAULT 0,
    allow_view_to TEXT NOT NULL DEFAULT 3
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_inputs_privacy criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_form_inputs_privacy: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_form_inputs_privacy: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_form_inputs_privacy.
  """
  def down do
    Logger.info("Removendo tabela de sys_form_inputs_privacy...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_form_inputs_privacy
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_form_inputs_privacy removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_form_inputs_privacy: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_form_inputs_privacy: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
