defmodule Repo.Migrations.CreateBxTimelineEfFiles do
  use Ecto.Migration

  def change do
    create table(:bx_timeline_ef_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_id, :integer, null: false, default: 0
      timestamps()
    end
  end
end
