defmodule DeeperHub.Core.Data.Migrations.Seeds.BxAdsCategoriesSeed do
  @moduledoc """
  Seed para a tabela bx_ads_categories.
  Insere os registros iniciais na tabela.
  """

  alias DeeperHub.Core.Data.Repo

  @doc """
  Insere os registros na tabela.
  """
  def run do
    IO.puts("Inserindo registros na tabela bx_ads_categories...")

        Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [1, 0, 0, 1, "job", "_bx_ads_cat_title_job", "", "user-md", 0, 1, 1])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [2, 1, 1, 1, "job_finance", "_bx_ads_cat_title_accounting_finance", "", "", 0, 1, 1])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [3, 1, 1, 1, "job_education", "_bx_ads_cat_title_education_nonprofit", "", "", 0, 1, 2])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [4, 1, 1, 1, "job_legal", "_bx_ads_cat_title_government_legal", "", "", 0, 1, 3])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [5, 1, 1, 1, "job_programming", "_bx_ads_cat_title_programming_web_design", "", "", 0, 1, 4])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [6, 0, 0, 2, "music", "_bx_ads_cat_title_music", "", "music", 0, 1, 2])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [7, 6, 1, 2, "music_isale", "_bx_ads_cat_title_instrument_sale", "", "", 0, 1, 1])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [8, 6, 1, 2, "music_iwanted", "_bx_ads_cat_title_instrument_wanted", "", "", 0, 1, 2])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [9, 0, 0, 1, "housing", "_bx_ads_cat_title_housing", "", "home", 0, 1, 3])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [10, 9, 1, 1, "housing_apartments", "_bx_ads_cat_title_apartments_housing", "", "", 0, 1, 1])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [11, 9, 1, 1, "housing_office", "_bx_ads_cat_title_office_commercial", "", "", 0, 1, 2])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [12, 9, 1, 1, "housing_re_sale", "_bx_ads_cat_title_real_estate_sale", "", "", 0, 1, 3])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [13, 9, 1, 1, "housing_roommate", "_bx_ads_cat_title_roommate", "", "", 0, 1, 4])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [14, 9, 1, 1, "housing_temp_rental", "_bx_ads_cat_title_temporary_rental", "", "", 0, 1, 5])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [15, 0, 0, 1, "service", "_bx_ads_cat_title_service", "", "wrench", 0, 1, 4])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [16, 15, 1, 1, "service_automotive", "_bx_ads_cat_title_automotive", "", "", 0, 1, 1])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [17, 15, 1, 1, "service_educational", "_bx_ads_cat_title_educational", "", "", 0, 1, 2])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [18, 15, 1, 1, "service_financial", "_bx_ads_cat_title_financial", "", "", 0, 1, 3])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [19, 15, 1, 1, "service_labor", "_bx_ads_cat_title_labor_move", "", "", 0, 1, 4])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [20, 15, 1, 1, "service_legal", "_bx_ads_cat_title_legal", "", "", 0, 1, 5])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [21, 0, 0, 1, "casting", "_bx_ads_cat_title_casting", "", "eye", 0, 1, 5])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [22, 21, 1, 1, "casting_acting", "_bx_ads_cat_title_acting", "", "", 0, 1, 1])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [23, 21, 1, 1, "casting_dance", "_bx_ads_cat_title_dance", "", "", 0, 1, 2])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [24, 21, 1, 1, "casting_modeling", "_bx_ads_cat_title_modeling", "", "", 0, 1, 3])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [25, 21, 1, 1, "casting_musician", "_bx_ads_cat_title_musician", "", "", 0, 1, 4])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [26, 21, 1, 1, "casting_rshow", "_bx_ads_cat_title_reality_show", "", "", 0, 1, 5])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [27, 0, 0, 2, "personal", "_bx_ads_cat_title_personal", "", "user", 0, 1, 6])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [28, 27, 1, 2, "personal_mw", "_bx_ads_cat_title_men_women", "", "", 0, 1, 1])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [29, 27, 1, 2, "personal_wm", "_bx_ads_cat_title_women_men", "", "", 0, 1, 2])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [30, 27, 1, 2, "personal_missed", "_bx_ads_cat_title_missed_connection", "", "", 0, 1, 3])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [31, 0, 0, 2, "sale", "_bx_ads_cat_title_sale", "", "shopping-cart", 0, 1, 7])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [32, 31, 1, 2, "sale_barter", "_bx_ads_cat_title_barter", "", "", 0, 1, 1])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [33, 31, 1, 2, "sale_clothing", "_bx_ads_cat_title_clothing", "", "", 0, 1, 1])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [34, 31, 1, 2, "sale_collectible", "_bx_ads_cat_title_collectible", "", "", 0, 1, 1])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [35, 0, 0, 2, "sale_car", "_bx_ads_cat_title_sale_car", "", "truck", 0, 1, 8])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [36, 35, 1, 2, "sale_car_part", "_bx_ads_cat_title_auto_part", "", "", 0, 1, 1])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [37, 35, 1, 2, "sale_car_auto", "_bx_ads_cat_title_auto_truck", "", "", 0, 1, 2])
    Repo.execute("INSERT INTO bx_ads_categories (id, parent_id, level, type, name, title, text, icon, items, active, order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [38, 35, 1, 2, "sale_car_motorcycle", "_bx_ads_cat_title_motorcycle", "", "", 0, 1, 3])

    IO.puts("Registros inseridos com sucesso!")
  end
end
