defmodule Repo.Migrations.CreateBxPaymentModules do
  use Ecto.Migration

  def change do
    create table(:bx_payment_modules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      timestamps()
    end
    create index(:bx_payment_modules, [:name], unique: true)
  end
end
