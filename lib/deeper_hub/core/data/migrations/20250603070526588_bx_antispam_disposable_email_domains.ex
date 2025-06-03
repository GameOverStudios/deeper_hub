defmodule DeeperHub.Core.Data.Migrations.BxAntispamDisposableEmailDomains do
  @moduledoc """
  Migration para criar e remover a tabela bx_antispam_disposable_email_domains.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_antispam_disposable_email_domains.
  """
  def up do
    Logger.info("Criando tabela de bx_antispam_disposable_email_domains...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_antispam_disposable_email_domains (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    domain TEXT NOT NULL,
    list TEXT NOT NULL DEFAULT 'custom_blacklist'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_disposable_email_domains criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_antispam_disposable_email_domains: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_antispam_disposable_email_domains: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_antispam_disposable_email_domains.
  """
  def down do
    Logger.info("Removendo tabela de bx_antispam_disposable_email_domains...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_antispam_disposable_email_domains
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_antispam_disposable_email_domains removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_antispam_disposable_email_domains: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_antispam_disposable_email_domains: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
