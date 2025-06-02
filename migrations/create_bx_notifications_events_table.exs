defmodule Repo.Migrations.CreateBxNotificationsEvents do
  use Ecto.Migration

  def change do
    create table(:bx_notifications_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :owner_id, :integer, null: false, default: 0
      add :type, :string, null: false
      add :action, :string, null: false
      add :object_id, :string, null: false
      add :object_owner_id, :integer, null: false, default: 0
      add :object_privacy_view, :string, null: false, default: "3"
      add :subobject_id, :integer, null: false, default: 0
      add :content, :string, null: false
      add :source, :string, null: false, default: ""
      add :allow_view_event_to, :string, null: false, default: "3"
      add :date, :integer, null: false, default: 0
      add :processed, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 1
      timestamps()
    end
    create index(:bx_notifications_events, [:owner_id])
    create index(:bx_notifications_events, [:object_owner_id])
  end
end
