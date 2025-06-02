defmodule Repo.Migrations.CreateBxReviewsVotingOptions do
  use Ecto.Migration

  def change do
    create table(:bx_reviews_voting_options, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :lkey, :string, null: false, default: ""
      add :order, :integer, null: false
      timestamps()
    end
  end
end
