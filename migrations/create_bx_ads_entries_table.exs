defmodule Repo.Migrations.CreateBxAdsEntries do
  use Ecto.Migration

  def change do
    create table(:bx_ads_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :sold, :integer, null: false
      add :shipped, :integer, null: false
      add :received, :integer, null: false
      add :source_type, :string, null: false, default: ""
      add :source, :string, null: false, default: ""
      add :category, :integer, null: false
      add :thumb, :integer, null: false
      add :name, :string, null: false
      add :title, :string, null: false
      add :url, :string, null: false
      add :price, :float, null: false
      add :auction, :integer, null: false, default: 0
      add :quantity, :integer, null: false, default: 1
      add :single, :integer, null: false, default: 1
      add :year, :integer, null: false
      add :text, :string, null: false
      add :notes_purchased, :string, null: false
      add :labels, :string, null: false
      add :tags, :string, null: false
      add :location, :string, null: false
      add :budget_total, :float, null: false, default: 0
      add :budget_daily, :float, null: false, default: 0
      add :impressions, :integer, null: false, default: 0
      add :clicks, :integer, null: false, default: 0
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
      add :reviews, :integer, null: false, default: 0
      add :reviews_avg, :float, null: false, default: 0
      add :reports, :integer, null: false, default: 0
      add :featured, :integer, null: false, default: 0
      add :seg, :integer, null: false, default: 0
      add :seg_gender, :integer, null: false, default: 0
      add :seg_age_min, :integer, null: false, default: 0
      add :seg_age_max, :integer, null: false, default: 0
      add :seg_tags, :integer, null: false, default: 0
      add :seg_country, :string, null: false, default: ""
      add :cf, :integer, null: false, default: 1
      add :allow_view_to, :string, null: false, default: "3"
      add :status, :string, null: false, default: "active"
      add :status_admin, :string, null: false, default: "active"
      timestamps()
    end
    create index(:bx_ads_entries, [:title])
  end
end
