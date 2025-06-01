# Migração gerada com ID único: V1748745504390 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysStdWidgetsTable do
  # Migração gerada com ID único: V1748745504390 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_std_widgets.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_std_widgets.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_std_widgets...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_std_widgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      page_id TEXT NOT NULL, -- Pode referenciar sys_std_pages.name
      module TEXT,
      type TEXT,
      url TEXT,
      click TEXT,
      icon TEXT,
      caption TEXT,
      cnt_notices TEXT, -- Lógica para contagem de notificações (geralmente string de service call no UNA)
      cnt_actions TEXT, -- Lógica para contagem de ações (geralmente string de service call no UNA)
      featured INTEGER NOT NULL DEFAULT 0 -- 0 ou 1
    );

    CREATE INDEX IF NOT EXISTS idx_sys_std_widgets_page_id ON sys_std_widgets(page_id);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_widgets criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_std_widgets: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_std_widgets.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_std_widgets...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS sys_std_widgets;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_std_widgets removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_std_widgets: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
