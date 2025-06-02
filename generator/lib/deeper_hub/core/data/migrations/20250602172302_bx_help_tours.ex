defmodule DeeperHub.Core.Data.Migrations.BxHelpTours do
  @moduledoc """
  Migration para criar e remover a tabela bx_help_tours.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_help_tours.
  """
  def up do
    Logger.info("Criando tabela de bx_help_tours...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_help_tours (
id int(11) NOT NULL  auto_increment,
overlay tinyint(1) NOT NULL,
page varchar(128) NOT NULL,
order int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_help_tours criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_help_tours: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_help_tours.
  """
  def down do
    Logger.info("Removendo tabela de bx_help_tours...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_help_tours
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_help_tours removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_help_tours: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
