# Migração gerada com ID único: V1748745504329 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysOptionsMixes2OptionsTable do
  # Migração gerada com ID único: V1748745504329 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_options_mixes2options.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_options_mixes2options.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_options_mixes2options...", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS sys_options_mixes2options (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      option_name TEXT NOT NULL, -- Refere-se a sys_options.name
      mix_id INTEGER NOT NULL,
      value TEXT NOT NULL, -- Valor da opção para este mix específico
      FOREIGN KEY (mix_id) REFERENCES sys_options_mixes(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_options_mixes2options_mix_id ON sys_options_mixes2options(mix_id);
    CREATE INDEX IF NOT EXISTS idx_sys_options_mixes2options_option_name ON sys_options_mixes2options(option_name);
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_options_mixes2options_option_mix ON sys_options_mixes2options(option_name, mix_id);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_options_mixes2options criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_options_mixes2options: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_options_mixes2options.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_options_mixes2options...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_options_mixes2options;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_options_mixes2options removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_options_mixes2options: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end