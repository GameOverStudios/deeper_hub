defmodule DeeperHub.Core.Data.Migrations.BxOrganizationsScoresTrack do
  @moduledoc """
  Migration para criar e remover a tabela bx_organizations_scores_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_organizations_scores_track.
  """
  def up do
    Logger.info("Criando tabela de bx_organizations_scores_track...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_organizations_scores_track (
id int(11) NOT NULL  auto_increment,
object_id int(11) NOT NULL DEFAULT 0,
author_id int(11) NOT NULL DEFAULT 0,
author_nip int(11) unsigned NOT NULL DEFAULT 0,
type varchar(8) NOT NULL DEFAULT,
date int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_organizations_scores_track criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_organizations_scores_track: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_organizations_scores_track.
  """
  def down do
    Logger.info("Removendo tabela de bx_organizations_scores_track...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_organizations_scores_track
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_organizations_scores_track removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_organizations_scores_track: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
