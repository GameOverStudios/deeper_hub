defmodule Repo.Migrations.CreateSysMenuItems do
  use Ecto.Migration

  def change do
    create table(:sys_menu_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :parent_id, :integer, null: false, default: 0
      add :set_name, :string, null: false
      add :module, :string, null: false
      add :name, :string, null: false
      add :title_system, :string, null: false
      add :title, :string, null: false
      add :title_attr, :string, null: false, default: ""
      add :link, :string, null: false
      add :onclick, :string, null: false
      add :target, :string, null: false
      add :area_label, :string, null: false, default: ""
      add :icon, :string, null: false
      add :icon_only, :integer, null: false, default: 0
      add :addon, :string, null: false
      add :addon_cache, :integer, null: false, default: 0
      add :markers, :string, null: false
      add :submenu_object, :string, null: false
      add :submenu_popup, :integer, null: false, default: 0
      add :visible_for_levels, :integer, null: false, default: 2147483647
      add :visibility_custom, :string, null: false
      add :hidden_on, :string, null: false, default: ""
      add :hidden_on_cxt, :string, null: false, default: ""
      add :hidden_on_pt, :integer, null: false, default: 0
      add :hidden_on_col, :integer, null: false, default: 0
      add :config_api, :string, null: false
      add :primary, :integer, null: false, default: 0
      add :collapsed, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 1
      add :active_api, :integer, null: false, default: 0
      add :copyable, :integer, null: false, default: 1
      add :editable, :integer, null: false, default: 1
      add :order, :integer, null: false
      timestamps()
    end
  end
end
