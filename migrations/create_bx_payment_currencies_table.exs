defmodule Repo.Migrations.CreateBxPaymentCurrencies do
  use Ecto.Migration

  def change do
    create table(:bx_payment_currencies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string, null: false, default: ""
      add :rate, :float, null: false, default: 0
      timestamps()
    end
    create index(:bx_payment_currencies, [:code], unique: true)
  end
end
