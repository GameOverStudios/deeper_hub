defmodule Repo.Migrations.CreateBxPaymentCommissions do
  use Ecto.Migration

  def change do
    create table(:bx_payment_commissions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :caption, :string, null: false, default: ""
      add :description, :string, null: false, default: ""
      add :acl_id, :integer, null: false, default: 0
      add :percentage, :float, null: false, default: 0
      add :installment, :float, null: false, default: 0
      add :active, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_payment_commissions, [:name], unique: true)
  end
end
