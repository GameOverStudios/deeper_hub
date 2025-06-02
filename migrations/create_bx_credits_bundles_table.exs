defmodule Repo.Migrations.CreateBxCreditsBundles do
  use Ecto.Migration

  def change do
    create table(:bx_credits_bundles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :added, :integer, null: false
      add :name, :string, null: false
      add :title, :string, null: false
      add :description, :string, null: false
      add :amount, :integer, null: false, default: 0
      add :bonus, :integer, null: false, default: 0
      add :price, :float, null: false, default: 0
      add :active, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      timestamps()
    end
  end
end
