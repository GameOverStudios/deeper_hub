defmodule Repo.Migrations.CreateBxEventsScores do
  use Ecto.Migration

  def change do
    create table(:bx_events_scores, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :count_up, :integer, null: false, default: 0
      add :count_down, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_events_scores, [:object_id], unique: true)
  end
end
