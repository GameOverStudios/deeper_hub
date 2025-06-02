defmodule Repo.Migrations.CreateBxNotificationsSettings do
  use Ecto.Migration

  def change do
    create table(:bx_notifications_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group, :string, null: false, default: ""
      add :handler_id, :integer, null: false, default: 0
      add :delivery, :string, null: false, default: "site"
      add :type, :string, null: false, default: "personal"
      add :title, :string, null: false, default: ""
      add :value, :integer, null: false, default: 1
      add :active, :integer, null: false, default: 1
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_notifications_settings, [:handler_id])
  end
end
