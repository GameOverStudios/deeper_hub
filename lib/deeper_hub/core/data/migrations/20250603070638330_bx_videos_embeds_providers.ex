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
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object TEXT NOT NULL,
    module TEXT NOT NULL,
    params TEXT NOT NULL,
    class_name TEXT NOT NULL,
    class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_videos_embeds_providers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_videos_embeds_providers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_videos_embeds_providers: #{inspect(reason)}", module: __MODULE__)
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

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_videos_embeds_providers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_videos_embeds_providers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
