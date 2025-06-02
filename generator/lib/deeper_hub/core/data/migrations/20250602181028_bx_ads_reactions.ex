defmodule DeeperHub.Core.Data.Migrations.BxAdsReactions do
  @moduledoc """
  Migration para criar e remover a tabela bx_ads_reactions.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_ads_reactions.
  """
  def up do
    Logger.info("Criando tabela de bx_ads_reactions...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_ads_reactions (
id int(11) NOT NULL  auto_increment,
object_id int(11) NOT NULL DEFAULT 0,
reaction varchar(32) NOT NULL DEFAULT,
count int(11) NOT NULL DEFAULT 0,
sum int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_reactions criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_reactions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_ads_reactions.
  """
  def down do
    Logger.info("Removendo tabela de bx_ads_reactions...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_ads_reactions
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_reactions removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_reactions: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
