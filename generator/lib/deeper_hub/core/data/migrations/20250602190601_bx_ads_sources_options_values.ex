defmodule DeeperHub.Core.Data.Migrations.BxAdsSourcesOptionsValues do
  @moduledoc """
  Migration para criar e remover a tabela bx_ads_sources_options_values.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_ads_sources_options_values.
  """
  def up do
    Logger.info("Criando tabela de bx_ads_sources_options_values...", module: __MODULE__)

    sql = """
CREATE TABLE IF NOT EXISTS bx_ads_sources_options_values (
id int(11) NOT NULL  auto_increment,
profile_id int(11) NOT NULL DEFAULT 0,
option_id int(11) NOT NULL DEFAULT 0,
value varchar(255) NOT NULL DEFAULT,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_sources_options_values criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_ads_sources_options_values: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_ads_sources_options_values.
  """
  def down do
    Logger.info("Removendo tabela de bx_ads_sources_options_values...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_ads_sources_options_values
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_ads_sources_options_values removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_ads_sources_options_values: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
