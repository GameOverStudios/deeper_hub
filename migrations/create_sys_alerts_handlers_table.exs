defmodule Repo.Migrations.CreateSysAlertsHandlers do
  use Ecto.Migration

  def change do
    create table(:sys_alerts_handlers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :class, :string, null: false, default: ""
      add :file, :string, null: false, default: ""
      add :service_call, :string, null: false, default: "''"
      add :active, :integer, null: false, default: 1
      timestamps()
    end
    create index(:sys_alerts_handlers, [:name], unique: true)
  end
end
