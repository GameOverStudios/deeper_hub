defmodule DeeperHub.Core.Data.Migrations.BxCreditsProfiles do
  @moduledoc """
  Migration para criar e remover a tabela bx_credits_profiles.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_credits_profiles.
  """
  def up do
    Logger.info("Criando tabela de bx_credits_profiles...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_credits_profiles (
id int(11) NOT NULL DEFAULT 0,
wdw_clearing int(11) unsigned NOT NULL DEFAULT 0,
wdw_minimum int(11) unsigned NOT NULL DEFAULT 0,
wdw_remaining int(11) unsigned NOT NULL DEFAULT 0,
balance float NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_profiles criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_credits_profiles: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_credits_profiles.
  """
  def down do
    Logger.info("Removendo tabela de bx_credits_profiles...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_credits_profiles
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_credits_profiles removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_credits_profiles: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
