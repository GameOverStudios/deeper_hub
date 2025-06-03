defmodule DeeperHub.Core.Data.Migrations.BxPaymentProvidersOptions do
  @moduledoc """
  Migration para criar e remover a tabela bx_payment_providers_options.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Cria a tabela de bx_payment_providers_options.
  """
  def up do
    Logger.info("Criando tabela de bx_payment_providers_options...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS bx_payment_providers_options (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    provider_id TEXT NOT NULL,
    name TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'text',
    caption TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '''',
    extra TEXT NOT NULL,
    check_type TEXT NOT NULL,
    check_params TEXT NOT NULL,
    check_error TEXT NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0
    );
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_providers_options criada com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao criar tabela de bx_payment_providers_options: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_providers_options: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Remove a tabela de bx_payment_providers_options.
  """
  def down do
    Logger.info("Removendo tabela de bx_payment_providers_options...", module: __MODULE__)

    sql = """
    DROP TABLE IF EXISTS bx_payment_providers_options
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_providers_options removida com sucesso.", module: __MODULE__)
        :ok

      {:error, %Exqlite.Error{message: message}} ->
        Logger.error("Falha ao remover tabela de bx_payment_providers_options: #{message}", module: __MODULE__)
        {:error, message}
        
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_providers_options: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
