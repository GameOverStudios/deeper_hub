defmodule DeeperHub.Core.Data.Migrations.BxConvosConv2folder do
  @moduledoc """
  Migration para criar e remover a tabela bx_convos_conv2folder.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_convos_conv2folder.
  """
  def up do
    Logger.info("Criando tabela de bx_convos_conv2folder...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_convos_conv2folder (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    conv_id INTEGER NOT NULL,
    folder_id INTEGER NOT NULL,
    collaborator INTEGER NOT NULL,
    read_comments INTEGER NOT NULL DEFAULT -1
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_convos_conv2folder criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_convos_conv2folder: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_convos_conv2folder: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_convos_conv2folder.
  """
  def down do
    Logger.info("Removendo tabela de bx_convos_conv2folder...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_convos_conv2folder
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_convos_conv2folder removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_convos_conv2folder: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_convos_conv2folder: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
