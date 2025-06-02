defmodule Repo.Migrations.CreateBxCreditsOrdersDeleted do
  use Ecto.Migration

  def change do
    create table(:bx_credits_orders_deleted, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :bundle_id, :integer, null: false, default: 0
      add :count, :integer, null: false, default: 0
      add :order, :string, null: false, default: ""
      add :license, :string, null: false, default: ""
      add :type, :string, null: false, default: ""
      add :added, :integer, null: false, default: 0
      add :expired, :integer, null: false, default: 0
      add :new, :boolean, null: false, default: true
      add :reason, :string, null: false, default: ""
      add :deleted, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_credits_orders_deleted, [:bundle_id])
    create index(:bx_credits_orders_deleted, [:license])
  end
end
