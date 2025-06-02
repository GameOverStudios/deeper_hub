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
id int(11) NOT NULL  auto_increment,
chain enum('spammers','whitelist','uridns') NOT NULL,
zonedomain varchar(255) NOT NULL,
postvresp varchar(32) NOT NULL,
url varchar(255) NOT NULL,
recheck varchar(255) NOT NULL,
comment varchar(255) NOT NULL,
added int(11) NOT NULL,
active tinyint(4) NOT NULL,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_dnsbl_rules criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_antispam_dnsbl_rules: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_antispam_dnsbl_rules: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
