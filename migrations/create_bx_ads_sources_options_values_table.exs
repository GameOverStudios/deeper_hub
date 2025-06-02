defmodule Repo.Migrations.CreateBxAdsSourcesOptionsValues do
  use Ecto.Migration

  def change do
    create table(:bx_ads_sources_options_values, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :option_id, :integer, null: false, default: 0
      add :value, :string, null: false, default: ""
      timestamps()
    end
    create index(:bx_ads_sources_options_values, [:profile_id])
  end
end
