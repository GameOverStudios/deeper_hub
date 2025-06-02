defmodule Repo.Migrations.CreateBxAdsPolls do
  use Ecto.Migration

  def change do
    create table(:bx_ads_polls, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author_id, :integer, null: false, default: 0
      add :content_id, :integer, null: false, default: 0
      add :text, :string, null: false
      timestamps()
    end
    create index(:bx_ads_polls, [:text])
  end
end
