defmodule Repo.Migrations.CreateSysObjectsChart do
  use Ecto.Migration

  def change do
    create table(:sys_objects_chart, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :title, :string, null: false
      add :table, :string, null: false
      add :field_date_ts, :string, null: false
      add :field_date_dt, :string, null: false
      add :field_status, :string, null: false
      add :column_date, :integer, null: false, default: 0
      add :column_count, :integer, null: false, default: 1
      add :type, :string, null: false
      add :options, :string, null: false
      add :query, :string, null: false
      add :active, :integer, null: false, default: 1
      add :order, :integer, null: false
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_objects_chart, [:object], unique: true)
  end
end
