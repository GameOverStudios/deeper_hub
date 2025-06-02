defmodule Repo.Migrations.CreateBxNotificationsSettings2users do
  use Ecto.Migration

  def change do
    create table(:bx_notifications_settings2users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :integer, null: false, default: 0
      add :setting_id, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 1
      timestamps()
    end
    create index(:bx_notifications_settings2users, [:setting_id])
  end
end
