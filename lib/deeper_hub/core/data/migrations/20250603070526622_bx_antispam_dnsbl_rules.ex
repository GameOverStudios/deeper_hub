defmodule DeeperHub.Core.Data.Migrations.BxAntispamDnsblRules do
  @moduledoc """
  Migration para criar e remover a tabela bx_antispam_dnsbl_rules.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_antispam_dnsbl_rules.
  """
  def up do
    Logger.info("Criando tabela de bx_antispam_dnsbl_rules...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_antispam_dnsbl_rules (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    chain TEXT NOT NULL,
    zonedomain TEXT NOT NULL,
    postvresp TEXT NOT NULL,
    url TEXT NOT NULL,
    recheck TEXT NOT NULL,
    comment TEXT NOT NULL,
    added INTEGER NOT NULL,
    active INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_dnsbl_rules criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_antispam_dnsbl_rules: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_antispam_dnsbl_rules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_antispam_dnsbl_rules.
  """
  def down do
    Logger.info("Removendo tabela de bx_antispam_dnsbl_rules...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_antispam_dnsbl_rules
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_dnsbl_rules removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_antispam_dnsbl_rules: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_antispam_dnsbl_rules: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
