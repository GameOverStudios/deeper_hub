defmodule Repo.Migrations.CreateSysObjectsGrid do
  use Ecto.Migration

  def change do
    create table(:sys_objects_grid, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :source_type, :string, null: false
      add :source, :string, null: false
      add :table, :string, null: false
      add :field_id, :string, null: false
      add :field_order, :string, null: false
      add :field_active, :string, null: false
      add :order_get_field, :string, null: false, default: "order_field"
      add :order_get_dir, :string, null: false, default: "order_dir"
      add :paginate_url, :string, null: false
      add :paginate_per_page, :integer, null: false, default: 10
      add :paginate_simple, :string
      add :paginate_get_start, :string, null: false
      add :paginate_get_per_page, :string, null: false
      add :filter_fields, :string, null: false
      add :filter_fields_translatable, :string, null: false
      add :filter_mode, :string, null: false, default: "auto"
      add :filter_get, :string, null: false, default: "filter"
      add :sorting_fields, :string, null: false
      add :sorting_fields_translatable, :string, null: false
      add :visible_for_levels, :integer, null: false, default: 2147483647
      add :responsive, :integer, null: false, default: 1
      add :show_total_count, :integer, null: false, default: 0
      add :override_class_name, :string, null: false
      add :override_class_file, :string, null: false
      timestamps()
    end
    create index(:sys_objects_grid, [:object], unique: true)
  end
end
