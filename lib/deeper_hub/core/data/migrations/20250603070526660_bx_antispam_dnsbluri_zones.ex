defmodule DeeperHub.Core.Data.Migrations.BxAntispamDnsbluriZones do
  @moduledoc """
  Migration para criar e remover a tabela bx_antispam_dnsbluri_zones.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_antispam_dnsbluri_zones.
  """
  def up do
    Logger.info("Criando tabela de bx_antispam_dnsbluri_zones...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_antispam_dnsbluri_zones (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    level INTEGER NOT NULL,
    zone TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_dnsbluri_zones criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_antispam_dnsbluri_zones: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_antispam_dnsbluri_zones: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_antispam_dnsbluri_zones.
  """
  def down do
    Logger.info("Removendo tabela de bx_antispam_dnsbluri_zones...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_antispam_dnsbluri_zones
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_dnsbluri_zones removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_antispam_dnsbluri_zones: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_antispam_dnsbluri_zones: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
