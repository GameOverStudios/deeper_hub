defmodule Repo.Migrations.CreateBxTimelineLinks2events do
  use Ecto.Migration

  def change do
    create table(:bx_timeline_links2events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_id, :integer, null: false, default: 0
      add :link_id, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_timeline_links2events, [:link_id])
  end
end
