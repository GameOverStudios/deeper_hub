defmodule Repo.Migrations.CreateSysAlertsCacheTriggers do
  use Ecto.Migration

  def change do
    create table(:sys_alerts_cache_triggers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :unit, :string, null: false, default: ""
      add :action, :string, null: false, default: ""
      add :cache_key, :string, null: false, default: ""
      timestamps()
    end
  end
end
