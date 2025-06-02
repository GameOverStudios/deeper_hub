defmodule Repo.Migrations.CreateBxTimelineEvents do
  use Ecto.Migration

  def change do
    create table(:bx_timeline_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :owner_id, :integer, null: false, default: 0
      add :system, :integer, null: false, default: 1
      add :type, :string, null: false
      add :action, :string, null: false
      add :object_id, :integer, null: false, default: 0
      add :object_owner_id, :integer, null: false, default: 0
      add :object_privacy_view, :string, null: false, default: "3"
      add :object_cf, :integer, null: false, default: 1
      add :content, :string, null: false
      add :source, :string, null: false, default: ""
      add :title, :string, null: false
      add :description, :string, null: false
      add :labels, :string, null: false
      add :location, :string, null: false
      add :views, :integer, null: false, default: 0
      add :rate, :float, null: false, default: 0
      add :votes, :integer, null: false, default: 0
      add :rrate, :float, null: false, default: 0
      add :rvotes, :integer, null: false, default: 0
      add :score, :integer, null: false, default: 0
      add :sc_up, :integer, null: false, default: 0
      add :sc_down, :integer, null: false, default: 0
      add :comments, :integer, null: false, default: 0
      add :reports, :integer, null: false, default: 0
      add :reposts, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      add :published, :integer, null: false, default: 0
      add :reacted, :integer, null: false, default: 0
      add :status, :string, null: false, default: "active"
      add :status_admin, :string, null: false, default: "active"
      add :active, :integer, null: false, default: 1
      add :pinned, :integer, null: false, default: 0
      add :sticked, :integer, null: false, default: 0
      add :promoted, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_timeline_events, [:owner_id])
    create index(:bx_timeline_events, [:object_id])
    create index(:bx_timeline_events, [:title])
  end
end
