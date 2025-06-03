defmodule DeeperHub.Core.Data.Migrations.SysPagesDesignBoxes do
  @moduledoc """
  Migration para criar e remover a tabela sys_pages_design_boxes.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de sys_pages_design_boxes.
  """
  def up do
    Logger.info("Criando tabela de sys_pages_design_boxes...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_pages_design_boxes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    template TEXT NOT NULL,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_design_boxes criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sys_pages_design_boxes: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de sys_pages_design_boxes.
  """
  def down do
    Logger.info("Removendo tabela de sys_pages_design_boxes...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS sys_pages_design_boxes
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sys_pages_design_boxes removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sys_pages_design_boxes: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
