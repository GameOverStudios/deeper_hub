defmodule Repo.Migrations.CreateBxPaymentSubscriptions do
  use Ecto.Migration

  def change do
    create table(:bx_payment_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :pending_id, :integer, null: false, default: 0
      add :customer_id, :string, null: false, default: ""
      add :subscription_id, :string, null: false, default: ""
      add :period, :integer, null: false, default: 1
      add :period_unit, :string, null: false, default: ""
      add :trial, :integer, null: false, default: 0
      add :date_add, :integer, null: false, default: 0
      add :date_next, :integer, null: false, default: 0
      add :pay_attempts, :integer, null: false, default: 0
      add :status, :string, null: false, default: "unpaid"
      timestamps()
    end
    create index(:bx_payment_subscriptions, [:pending_id], unique: true)
  end
end
