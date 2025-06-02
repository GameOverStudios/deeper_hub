defmodule DeeperHub.Core.Data.Migrations.Seeds.BxAdsSourcesOptionsSeed do
  @moduledoc """
  Seed para a tabela bx_ads_sources_options.
  Insere os registros iniciais na tabela.
  """

  alias DeeperHub.Core.Data.Repo

  @doc """
  Insere os registros na tabela.
  """
  def run do
    IO.puts("Inserindo registros na tabela bx_ads_sources_options...")

        Repo.execute("INSERT INTO bx_ads_sources_options (id, source_id, name, type, caption, description, extra, check_type, check_params, check_error, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [1, "1", "shf_adm_active", "checkbox", "_bx_ads_src_opt_cpt_active", "_bx_ads_src_opt_dsc_active", "", "", "", "", 1])
    Repo.execute("INSERT INTO bx_ads_sources_options (id, source_id, name, type, caption, description, extra, check_type, check_params, check_error, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [2, "1", "shf_adm_shop_domain", "text", "_bx_ads_src_opt_cpt_shop_domain", "_bx_ads_src_opt_dsc_shop_domain", "", "", "", "", 2])
    Repo.execute("INSERT INTO bx_ads_sources_options (id, source_id, name, type, caption, description, extra, check_type, check_params, check_error, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [3, "1", "shf_adm_access_token", "text", "_bx_ads_src_opt_cpt_access_token", "_bx_ads_src_opt_dsc_access_token", "", "", "", "", 3])

    IO.puts("Registros inseridos com sucesso!")
  end
end
