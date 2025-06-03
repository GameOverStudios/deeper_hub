defmodule DeeperHub.Core.Data.Migrations.BxConvosConversations do
  @moduledoc """
  Migration para criar e remover a tabela bx_convos_conversations.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_convos_conversations.
  """
  def up do
    Logger.info("Criando tabela de bx_convos_conversations...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_convos_conversations (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    author INTEGER NOT NULL,
    added INTEGER NOT NULL,
    changed INTEGER NOT NULL,
    text TEXT NOT NULL,
    allow_edit INTEGER NOT NULL DEFAULT 0,
    views INTEGER NOT NULL DEFAULT 0,
    comments INTEGER NOT NULL DEFAULT 0,
    last_reply_timestamp INTEGER NOT NULL,
    last_reply_profile_id INTEGER NOT NULL,
    last_reply_comment_id INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_convos_conversations criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_convos_conversations: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_convos_conversations: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_convos_conversations.
  """
  def down do
    Logger.info("Removendo tabela de bx_convos_conversations...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_convos_conversations
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_convos_conversations removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_convos_conversations: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_convos_conversations: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
