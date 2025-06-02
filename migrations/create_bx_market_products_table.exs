defmodule Repo.Migrations.CreateBxMarketProducts do
  use Ecto.Migration

  def change do
    create table(:bx_market_products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      add :changed, :integer, null: false, default: 0
      add :thumb, :integer, null: false, default: 0
      add :cover, :integer, null: false, default: 0
      add :cover_data, :string, null: false, default: ""
      add :cover_raw, :string, null: false
      add :package, :integer, null: false, default: 0
      add :name, :string, null: false
      add :title, :string, null: false
      add :text, :string, null: false
      add :notes, :string, null: false
      add :notes_purchased, :string, null: false
      add :cat, :integer, null: false
      add :price_single, :float, null: false, default: 0
      add :price_recurring, :float, null: false, default: 0
      add :duration_recurring, :string, null: false, default: "month"
      add :trial_recurring, :integer, null: false, default: 0
      add :labels, :string, null: false
      add :location, :string, null: false
      add :views, :integer, null: false, default: 0
      add :rate, :float, null: false, default: 0
      add :votes, :integer, null: false, default: 0
      add :rrate, :float, null: false, default: 0
      add :rvotes, :integer, null: false, default: 0
      add :score, :integer, null: false, default: 0
      add :sc_up, :integer, null: false, default: 0
      add :sc_down, :integer, null: false, default: 0
      add :favorites, :integer, null: false, default: 0
      add :comments, :integer, null: false, default: 0
      add :reports, :integer, null: false, default: 0
      add :featured, :integer, null: false, default: 0
      add :cf, :integer, null: false, default: 1
      add :allow_view_to, :string, null: false, default: "3"
      add :allow_purchase_to, :string, null: false, default: "3"
      add :allow_comment_to, :string, null: false, default: "c"
      add :allow_vote_to, :string, null: false, default: "c"
      add :status, :string, null: false, default: "active"
      add :status_admin, :string, null: false, default: "active"
      timestamps()
    end
    create index(:bx_market_products, [:name], unique: true)
    create index(:bx_market_products, [:title])
  end
end
