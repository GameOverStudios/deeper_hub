defmodule DeeperHub.Core.Data.Migrations.SysTranscoderFilters do
  @moduledoc """
  Migration para criar e remover a tabela sys_transcoder_filters.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_transcoder_filters.
  """
  def up do
    Logger.info("Criando tabela de sys_transcoder_filters...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_transcoder_filters (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    transcoder_object TEXT NOT NULL,
    filter TEXT NOT NULL,
    filter_params TEXT NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_transcoder_filters criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de sys_transcoder_filters: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_transcoder_filters: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_transcoder_filters.
  """
  def down do
    Logger.info("Removendo tabela de sys_transcoder_filters...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_transcoder_filters
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_transcoder_filters removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de sys_transcoder_filters: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_transcoder_filters: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
