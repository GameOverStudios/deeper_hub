defmodule Repo.Migrations.CreateBxNotificationsQueue do
  use Ecto.Migration

  def change do
    create table(:bx_notifications_queue, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :event_id, :integer, null: false, default: 0
      add :delivery, :string, null: false, default: ""
      add :content, :string, null: false
      add :date, :integer, null: false, default: 0
      timestamps()
    end
  end
end
