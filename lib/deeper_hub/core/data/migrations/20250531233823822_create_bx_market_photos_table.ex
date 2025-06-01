# Migração gerada com ID único: V1748745503821 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateBxMarketPhotosTable do
  # Migração gerada com ID único: V1748745503821 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela bx_market_photos.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_market_photos.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_market_photos...", module: __MODULE__)

    # Assumindo que a tabela 'deeper_files' do módulo 06_file_management já existe
    # ou que a FK para file_id será adicionada/gerenciada posteriormente se não existir.
    # Para esta migração inicial, vamos definir a FK, mas ela só funcionará se a tabela referenciada existir.
    sql = """
    CREATE TABLE IF NOT EXISTS bx_market_photos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entry_id INTEGER NOT NULL,
      file_id INTEGER NOT NULL, -- Deveria referenciar deeper_files.id
      title TEXT,
      is_main INTEGER NOT NULL DEFAULT 0 CHECK(is_main IN (0,1)),
      order_index INTEGER NOT NULL DEFAULT 0,

      FOREIGN KEY (entry_id) REFERENCES bx_market_entries(id) ON DELETE CASCADE
      -- FOREIGN KEY (file_id) REFERENCES deeper_files(id) ON DELETE CASCADE -- Descomentar/ajustar quando deeper_files estiver definida
    );

    CREATE INDEX IF NOT EXISTS idx_bx_market_photos_entry_id ON bx_market_photos(entry_id);
    CREATE INDEX IF NOT EXISTS idx_bx_market_photos_file_id ON bx_market_photos(file_id);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_market_photos criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_market_photos: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_market_photos.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_market_photos...", module: __MODULE__)

    sql = "DROP TABLE IF EXISTS bx_market_photos;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_market_photos removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_market_photos: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end