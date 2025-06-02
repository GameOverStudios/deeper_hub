defmodule Repo.Migrations.CreateSysObjectsScore do
  use Ecto.Migration

  def change do
    create table(:sys_objects_score, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :module, :string, null: false
      add :table_main, :string, null: false, default: ""
      add :table_track, :string, null: false, default: ""
      add :post_timeout, :integer, null: false, default: 0
      add :pruning, :integer, null: false, default: 31536000
      add :is_undo, :boolean, null: false, default: false
      add :is_on, :boolean, null: false, default: true
      add :trigger_table, :string, null: false, default: ""
      add :trigger_field_id, :string, null: false, default: ""
      add :trigger_field_author, :string, null: false, default: ""
      add :trigger_field_score, :string, null: false, default: ""
      add :trigger_field_cup, :string, null: false, default: ""
      add :trigger_field_cdown, :string, null: false, default: ""
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
  end
end
