defmodule Repo.Migrations.CreateBxReviewsReviews do
  use Ecto.Migration

  def change do
    create table(:bx_reviews_reviews, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :thumb, :integer, null: false
      add :title, :string, null: false
      add :voting_options, :string, null: false
      add :voting_avg, :float, null: false
      add :cat, :integer, null: false
      add :multicat, :string, null: false
      add :text, :string, null: false
      add :labels, :string, null: false
      add :location, :string, null: false
      add :views, :integer, null: false, default: 0
      add :rate, :float, null: false, default: 0
      add :votes, :integer, null: false, default: 0
      add :srate, :float, null: false, default: 0
      add :svotes, :integer, null: false, default: 0
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
      add :reviewed_profile, :integer, null: false, default: 0
      add :product, :string, null: false
      add :allow_comments, :integer, null: false, default: 1
      add :status, :string, null: false, default: "active"
      add :status_admin, :string, null: false, default: "active"
      timestamps()
    end
    create index(:bx_reviews_reviews, [:title])
    create index(:bx_reviews_reviews, [:reviewed_profile])
  end
end
