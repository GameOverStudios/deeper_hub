defmodule Repo.Migrations.CreateBxEventsCheckIn do
  use Ecto.Migration

  def change do
    create table(:bx_events_check_in, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false
      add :event_id, :integer, null: false
      timestamps()
    end
    create index(:bx_events_check_in, [:profile_id], unique: true)
  end
end
