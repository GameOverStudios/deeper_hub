defmodule DeeperHub.Core.Data.Migrations.Seeds.BxAdsSourcesSeed do
  @moduledoc """
  Seed para a tabela bx_ads_sources.
  Insere os registros iniciais na tabela.
  """

  alias DeeperHub.Core.Data.Repo

  @doc """
  Insere os registros na tabela.
  """
  def run do
    IO.puts("Inserindo registros na tabela bx_ads_sources...")

        Repo.execute("INSERT INTO bx_ads_sources (id, name, caption, description, option_prefix, active, order, class_name, class_file) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", [1, "shopify_admin", "_bx_ads_src_cpt_shopify_admin", "_bx_ads_src_dsc_shopify_admin", "shf_adm_", 1, 1, "BxAdsSourceShopifyAdmin", ""])

    IO.puts("Registros inseridos com sucesso!")
  end
end
