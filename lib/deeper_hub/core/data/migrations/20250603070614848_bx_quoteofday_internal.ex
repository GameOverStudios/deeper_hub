defmodule DeeperHub.Core.Data.Migrations.BxQuoteofdayInternal do
  @moduledoc """
  Migration para criar e remover a tabela bx_quoteofday_internal.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_quoteofday_internal.
  """
  def up do
    Logger.info("Criando tabela de bx_quoteofday_internal...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_quoteofday_internal (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    text TEXT NOT NULL,
    added INTEGER NULL,
    status TEXT NULL DEFAULT 'active'
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_quoteofday_internal criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_quoteofday_internal: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_quoteofday_internal: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_quoteofday_internal.
  """
  def down do
    Logger.info("Removendo tabela de bx_quoteofday_internal...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_quoteofday_internal
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_quoteofday_internal removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_quoteofday_internal: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_quoteofday_internal: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
