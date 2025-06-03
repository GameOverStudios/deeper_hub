defmodule DeeperHub.Core.Data.Migrations.BxMarketFiles2products do
  @moduledoc """
  Migration para criar e remover a tabela bx_market_files2products.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_market_files2products.
  """
  def up do
    Logger.info("Criando tabela de bx_market_files2products...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_market_files2products (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    content_id INTEGER NOT NULL,
    file_id INTEGER NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'version',
    version TEXT NOT NULL,
    version_to TEXT NOT NULL,
    downloads INTEGER NOT NULL,
    "order" INTEGER NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_market_files2products criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_market_files2products: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_market_files2products: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_market_files2products.
  """
  def down do
    Logger.info("Removendo tabela de bx_market_files2products...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_market_files2products
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_market_files2products removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_market_files2products: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_market_files2products: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
