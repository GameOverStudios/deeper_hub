defmodule Repo.Migrations.CreateBxMarketPhotos2products do
  use Ecto.Migration

  def change do
    create table(:bx_market_photos2products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content_id, :integer, null: false
      add :file_id, :integer, null: false
      add :title, :string, null: false
      add :order, :integer, null: false
      timestamps()
    end
    create index(:bx_market_photos2products, [:content_id])
    create index(:bx_market_photos2products, [:file_id])
  end
end
