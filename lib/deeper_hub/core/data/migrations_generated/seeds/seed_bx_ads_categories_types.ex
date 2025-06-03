defmodule DeeperHub.Core.Data.Migrations.Seeds.SeedBxAdsCategoriesTypes do
  @moduledoc """
  Seed para a tabela bx_ads_categories_types.
  Insere os registros iniciais na tabela.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Insere os registros na tabela.
  Retorna `:ok` se todos os registros foram inseridos com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  def run do
    Logger.info("Inserindo registros na tabela bx_ads_categories_types...", module: __MODULE__)
    
    try do
      # Executar as inserções em uma transação para garantir atomicidade
      Repo.transaction(fn _conn ->
        # Primeiro registro
        case Repo.execute("INSERT INTO bx_ads_categories_types (id, name, title, display_add, display_edit, display_view) VALUES (?, ?, ?, ?, ?, ?)", 
                         [1, "price", "_bx_ads_cat_type_price", "bx_ads_entry_price_add", "bx_ads_entry_price_edit", "bx_ads_entry_price_view"]) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, {:insert_failed, 1, reason}}
        end
        
        # Segundo registro
        case Repo.execute("INSERT INTO bx_ads_categories_types (id, name, title, display_add, display_edit, display_view) VALUES (?, ?, ?, ?, ?, ?)", 
                         [2, "price_year", "_bx_ads_cat_type_price_year", "bx_ads_entry_price_year_add", "bx_ads_entry_price_year_edit", "bx_ads_entry_price_year_view"]) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, {:insert_failed, 2, reason}}
        end
      end)
      
      Logger.info("Registros inseridos com sucesso na tabela bx_ads_categories_types.", module: __MODULE__)
      :ok
    rescue
      e ->
        Logger.error("Exceção ao inserir registros na tabela bx_ads_categories_types: #{inspect(e)}", module: __MODULE__)
        {:error, e}
    end
  end
end
