defmodule DeeperHub.Core.Data.Migrations.{{MODULE_NAME}} do
  @moduledoc """
  Migration para criar e remover a tabela {{TABLE_NAME}}.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de {{TABLE_NAME}}.
  """
  def up do
    Logger.info("Criando tabela de {{TABLE_NAME}}...", module: __MODULE__)

    sql = """
{{CREATE_TABLE_SQL}}
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de {{TABLE_NAME}} criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de {{TABLE_NAME}}: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de {{TABLE_NAME}}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de {{TABLE_NAME}}.
  """
  def down do
    Logger.info("Removendo tabela de {{TABLE_NAME}}...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS {{TABLE_NAME}}
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de {{TABLE_NAME}} removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de {{TABLE_NAME}}: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de {{TABLE_NAME}}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
