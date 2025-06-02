defmodule Repo.Migrations.CreateSysObjectsLogs do
  use Ecto.Migration

  def change do
    create table(:sys_objects_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object, :string, null: false
      add :module, :string, null: false
      add :logs_storage, :string, null: false
      add :title, :string, null: false
      add :active, :integer, null: false, default: 1
      add :class_name, :string, null: false
      add :class_file, :string, null: false
      timestamps()
    end
  end
end
