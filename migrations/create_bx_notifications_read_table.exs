defmodule Repo.Migrations.CreateBxNotificationsRead do
  use Ecto.Migration

  def change do
    create table(:bx_notifications_read, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :integer, null: false, default: 0
      add :event_id, :integer, null: false, default: 0
      timestamps()
    end
  end
end
