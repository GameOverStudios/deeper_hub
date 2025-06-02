defmodule Repo.Migrations.CreateBxTimelineFiles2events do
  use Ecto.Migration

  def change do
    create table(:bx_timeline_files2events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_id, :integer, null: false, default: 0
      add :media_id, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_timeline_files2events, [:event_id])
  end
end
