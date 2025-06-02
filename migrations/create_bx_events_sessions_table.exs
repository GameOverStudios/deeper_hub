defmodule Repo.Migrations.CreateBxEventsSessions do
  use Ecto.Migration

  def change do
    create table(:bx_events_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_id, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      add :title, :string, null: false, default: ""
      add :description, :string, null: false
      add :date_start, :integer
      add :date_end, :integer
      add :order, :integer, null: false, default: 0
      timestamps()
    end
  end
end
