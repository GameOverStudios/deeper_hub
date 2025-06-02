defmodule Repo.Migrations.CreateSysAlerts do
  use Ecto.Migration

  def change do
    create table(:sys_alerts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :unit, :string, null: false, default: ""
      add :action, :string, null: false, default: "none"
      add :handler_id, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_alerts, [:unit])
  end
end
