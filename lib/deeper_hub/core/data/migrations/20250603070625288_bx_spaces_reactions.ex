defmodule DeeperHub.Core.Data.Migrations.BxSpacesReactions do
  @moduledoc """
  Migration para criar e remover a tabela bx_spaces_reactions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_spaces_reactions.
  """
  def up do
    Logger.info("Criando tabela de bx_spaces_reactions...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_spaces_reactions (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL DEFAULT 0,
    reaction TEXT NOT NULL,
    count INTEGER NOT NULL DEFAULT 0,
    sum INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_spaces_reactions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_spaces_reactions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_spaces_reactions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_spaces_reactions.
  """
  def down do
    Logger.info("Removendo tabela de bx_spaces_reactions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_spaces_reactions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_spaces_reactions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_spaces_reactions: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_spaces_reactions: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
