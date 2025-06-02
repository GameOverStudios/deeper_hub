defmodule Repo.Migrations.CreateBxMarketMetaKeywords do
  use Ecto.Migration

  def change do
    create table(:bx_market_meta_keywords, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false
      add :keyword, :string, null: false
      timestamps()
    end
    create index(:bx_market_meta_keywords, [:object_id])
    create index(:bx_market_meta_keywords, [:keyword])
  end
end
