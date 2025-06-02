defmodule DeeperHub.Core.Data.Migrations.BxHelpToursTrackViews do
  @moduledoc """
  Migration para criar e remover a tabela bx_help_tours_track_views.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_help_tours_track_views.
  """
  def up do
    Logger.info("Criando tabela de bx_help_tours_track_views...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_help_tours_track_views (
account int(11) NOT NULL,
tour int(11) NOT NULL,
  PRIMARY KEY (account),
  PRIMARY KEY (tour)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_help_tours_track_views criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_help_tours_track_views: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_help_tours_track_views.
  """
  def down do
    Logger.info("Removendo tabela de bx_help_tours_track_views...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_help_tours_track_views
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_help_tours_track_views removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_help_tours_track_views: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
