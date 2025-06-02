defmodule Repo.Migrations.CreateBxEventsIntervals do
  use Ecto.Migration

  def change do
    create table(:bx_events_intervals, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :interval_id, :integer, null: false
      add :event_id, :integer, null: false
      add :repeat_year, :integer, null: false
      add :repeat_month, :integer, null: false
      add :repeat_week_of_month, :integer, null: false
      add :repeat_day_of_month, :integer, null: false
      add :repeat_day_of_week, :integer, null: false
      add :repeat_stop, :integer, null: false
      timestamps()
    end
    create index(:bx_events_intervals, [:event_id])
  end
end
