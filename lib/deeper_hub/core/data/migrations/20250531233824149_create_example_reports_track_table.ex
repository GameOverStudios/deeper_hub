# Migração gerada com ID único: V1748745504148 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateExampleReportsTrackTable do
  # Migração gerada com ID único: V1748745504148 em 2025-05-31 23:38:24
  @moduledoc """
  Migração EXEMPLO para criar uma tabela de rastreamento de denúncias.
  O nome real da tabela viria de sys_objects_report.table_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @table_name "example_reports_track" # Este nome seria dinâmico

  @doc """
  Executa a migração para criar a tabela de exemplo.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela de exemplo de rastreamento de denúncias: #{@table_name}...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS #{@table_name} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- ID do item de conteúdo denunciado
      author_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem denunciou)
      author_nip INTEGER, -- IP do autor como inteiro
      type TEXT NOT NULL DEFAULT '', -- Tipo da denúncia
      "text" TEXT NOT NULL, -- Detalhes da denúncia
      date INTEGER NOT NULL, -- Unix Timestamp
      checked_by INTEGER DEFAULT 0, -- ID do admin que verificou (FK para sys_profiles.id ou sys_accounts.id)
      status INTEGER NOT NULL DEFAULT 0, -- Status da denúncia (ex: 0=pendente, 1=aceita, 2=rejeitada)
      FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
      -- A FK para object_id dependeria do tipo de conteúdo.
      -- A FK para checked_by (se > 0) para sys_profiles.id
      -- FOREIGN KEY (checked_by) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_object_id ON #{@table_name}(object_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_author_id ON #{@table_name}(author_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_status_date ON #{@table_name}(status, date);
    -- Pode-se adicionar um índice UNIQUE(object_id, author_id, type) se um usuário não puder denunciar
    -- o mesmo item pelo mesmo motivo múltiplas vezes.
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela #{@table_name} criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela #{@table_name}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela de exemplo.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela #{@table_name}...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS #{@table_name};"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela #{@table_name} removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela #{@table_name}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end