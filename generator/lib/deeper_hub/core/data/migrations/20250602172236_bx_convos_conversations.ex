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
id int(10) unsigned NOT NULL  auto_increment,
author int(10) unsigned NOT NULL,
added int(11) NOT NULL,
changed int(11) NOT NULL,
text text NOT NULL,
allow_edit tinyint(4) NOT NULL DEFAULT 0,
views int(11) NOT NULL DEFAULT 0,
comments int(11) NOT NULL DEFAULT 0,
last_reply_timestamp int(11) NOT NULL,
last_reply_profile_id int(10) unsigned NOT NULL,
last_reply_comment_id int(11) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_convos_conversations criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_convos_conversations: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_convos_conversations: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
