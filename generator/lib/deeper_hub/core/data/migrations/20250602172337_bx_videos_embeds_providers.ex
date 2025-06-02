defmodule DeeperHub.Core.Data.Migrations.BxVideosEmbedsProviders do
  @moduledoc """
  Migration para criar e remover a tabela bx_videos_embeds_providers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_videos_embeds_providers.
  """
  def up do
    Logger.info("Criando tabela de bx_videos_embeds_providers...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_videos_embeds_providers (
id int(11) NOT NULL  auto_increment,
object varchar(64) NOT NULL,
module varchar(64) NOT NULL,
params text NOT NULL,
class_name varchar(255) NOT NULL,
class_file varchar(255) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_videos_embeds_providers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_videos_embeds_providers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_videos_embeds_providers.
  """
  def down do
    Logger.info("Removendo tabela de bx_videos_embeds_providers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_videos_embeds_providers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_videos_embeds_providers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_videos_embeds_providers: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
