defmodule DeeperHub.Core.Data.Migrations.BxPaymentProviders do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_providers.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_providers.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_providers...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_payment_providers (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    caption TEXT NOT NULL,
    description TEXT NOT NULL,
    option_prefix TEXT NOT NULL,
    for_visitor INTEGER NOT NULL DEFAULT 0,
    for_owner_only INTEGER NOT NULL DEFAULT 0,
    for_single INTEGER NOT NULL DEFAULT 0,
    for_recurring INTEGER NOT NULL DEFAULT 0,
    single_seller INTEGER NOT NULL DEFAULT 0,
    time_tracker INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 0,
    "order" INTEGER NOT NULL DEFAULT 0,
    class_name TEXT NOT NULL,
    class_file TEXT NOT NULL
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_providers criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_payment_providers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_providers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_providers.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_providers...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_providers
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_providers removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_payment_providers: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_providers: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
