defmodule DeeperHub.Core.Data.Migrations.Seeds.BxAdsCategoriesTypesSeed do
  @moduledoc """
  Seed para a tabela bx_ads_categories_types.
  Insere os registros iniciais na tabela.
  """

  alias DeeperHub.Core.Data.Repo

  @doc """
  Insere os registros na tabela.
  """
  def run do
    IO.puts("Inserindo registros na tabela bx_ads_categories_types...")

        Repo.execute("INSERT INTO bx_ads_categories_types (id, name, title, display_add, display_edit, display_view) VALUES (?, ?, ?, ?, ?, ?)", [1, "price", "_bx_ads_cat_type_price", "bx_ads_entry_price_add", "bx_ads_entry_price_edit", "bx_ads_entry_price_view"])
    Repo.execute("INSERT INTO bx_ads_categories_types (id, name, title, display_add, display_edit, display_view) VALUES (?, ?, ?, ?, ?, ?)", [2, "price_year", "_bx_ads_cat_type_price_year", "bx_ads_entry_price_year_add", "bx_ads_entry_price_year_edit", "bx_ads_entry_price_year_view"])

    IO.puts("Registros inseridos com sucesso!")
  end
end
