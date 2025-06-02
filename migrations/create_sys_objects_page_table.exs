defmodule Repo.Migrations.CreateSysObjectsPage do
  use Ecto.Migration

  def change do
    create table(:sys_objects_page, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      add :object, :string, null: false
      add :uri, :string, null: false
      add :title_system, :string, null: false
      add :title, :string, null: false
      add :module, :string, null: false
      add :cover, :integer, null: false, default: 1
      add :cover_image, :integer, null: false, default: 0
      add :cover_title, :string, null: false, default: ""
      add :type_id, :integer, null: false, default: 1
      add :layout_id, :integer, null: false
      add :sticky_columns, :integer, null: false, default: 0
      add :submenu, :string, null: false, default: ""
      add :visible_for_levels, :integer, null: false, default: 2147483647
      add :visible_for_levels_editable, :integer, null: false, default: 1
      add :url, :string, null: false
      add :content_info, :string, null: false
      add :meta_title, :string, null: false
      add :meta_description, :string, null: false
      add :meta_keywords, :string, null: false
      add :meta_robots, :string, null: false
      add :cache_lifetime, :integer, null: false, default: 0
      add :cache_editable, :integer, null: false, default: 1
      add :inj_head, :string, null: false
      add :inj_footer, :string, null: false
      add :config_api, :string, null: false
      add :deletable, :boolean, null: false
      add :override_class_name, :string, null: false
      add :override_class_file, :string, null: false
      timestamps()
    end
    create index(:sys_objects_page, [:object], unique: true)
    create index(:sys_objects_page, [:uri], unique: true)
  end
end
