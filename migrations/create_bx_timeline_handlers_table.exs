defmodule Repo.Migrations.CreateBxTimelineHandlers do
  use Ecto.Migration

  def change do
    create table(:bx_timeline_handlers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group, :string, null: false, default: ""
      add :type, :string, null: false, default: "insert"
      add :alert_unit, :string, null: false, default: ""
      add :alert_action, :string, null: false, default: ""
      add :content, :string, null: false
      add :privacy, :string, null: false, default: ""
      timestamps()
    end
    create index(:bx_timeline_handlers, [:alert_unit])
  end
end
