defmodule Repo.Migrations.CreateBxTimelineEvents2users do
  use Ecto.Migration

  def change do
    create table(:bx_timeline_events2users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :integer, null: false, default: 0
      add :event_id, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_timeline_events2users, [:user_id])
  end
end
