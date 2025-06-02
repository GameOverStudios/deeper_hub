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
id int(11) NOT NULL  auto_increment,
provider_id varchar(64) NOT NULL DEFAULT,
name varchar(64) NOT NULL DEFAULT,
type varchar(64) NOT NULL DEFAULT text,
caption varchar(255) NOT NULL DEFAULT,
description text NOT NULL DEFAULT '',
extra varchar(255) NOT NULL DEFAULT,
check_type varchar(64) NOT NULL DEFAULT,
check_params varchar(128) NOT NULL DEFAULT,
check_error varchar(128) NOT NULL DEFAULT,
order tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de bx_payment_providers_options criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela de bx_payment_providers_options: #{reason}", module: __MODULE__)
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

      {:error, reason} ->
        Logger.error("Falha ao remover tabela de bx_payment_providers_options: #{reason}", module: __MODULE__)
        {:error, reason}
    end
  end
end
