defmodule Repo.Migrations.CreateSysObjectsLiveUpdates do
  use Ecto.Migration

  def change do
    create table(:sys_objects_live_updates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :init, :integer, null: false, default: 0
      add :frequency, :integer, null: false, default: 1
      add :service_call, :string, null: false, default: "''"
      add :active, :integer, null: false, default: 1
      timestamps()
    end
    create index(:sys_objects_live_updates, [:name], unique: true)
  end
end
