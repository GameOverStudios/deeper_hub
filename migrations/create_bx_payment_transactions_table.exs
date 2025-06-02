defmodule Repo.Migrations.CreateBxPaymentTransactions do
  use Ecto.Migration

  def change do
    create table(:bx_payment_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :pending_id, :integer, null: false, default: 0
      add :client_id, :integer, null: false, default: 0
      add :seller_id, :integer, null: false, default: 0
      add :author_id, :integer, null: false, default: 0
      add :module_id, :integer, null: false, default: 0
      add :item_id, :integer, null: false, default: 0
      add :item_count, :integer, null: false, default: 0
      add :amount, :float, null: false, default: 0
      add :currency, :string, null: false, default: ""
      add :license, :string, null: false, default: ""
      add :date, :integer, null: false, default: 0
      add :new, :boolean, null: false, default: true
      timestamps()
    end
  end
end
