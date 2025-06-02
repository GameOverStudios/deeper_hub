defmodule Repo.Migrations.CreateSysObjectsConnection do
  use Ecto.Migration

  def change do
    create table(:sys_objects_connection, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :table, :string, null: false
      add :profile_initiator, :integer, null: false, default: 1
      add :profile_content, :integer, null: false, default: 0
      add :type, :string, null: false
      add :tt_initiator, :string, null: false, default: ""
      add :tf_id_initiator, :string, null: false, default: ""
      add :tf_count_initiator, :string, null: false, default: ""
      add :tt_content, :string, null: false, default: ""
      add :tf_id_content, :string, null: false, default: ""
      add :tf_count_content, :string, null: false, default: ""
      add :override_class_name, :string, null: false
      add :override_class_file, :string, null: false
      timestamps()
    end
    create index(:sys_objects_connection, [:object], unique: true)
  end
end
