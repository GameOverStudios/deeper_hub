defmodule Repo.Migrations.CreateBxMarketSubproducts do
  use Ecto.Migration

  def change do
    create table(:bx_market_subproducts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :initiator, :integer, null: false
      add :content, :integer, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:bx_market_subproducts, [:initiator])
    create index(:bx_market_subproducts, [:content])
  end
end
