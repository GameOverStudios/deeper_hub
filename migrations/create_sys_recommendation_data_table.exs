defmodule Repo.Migrations.CreateSysRecommendationData do
  use Ecto.Migration

  def change do
    create table(:sys_recommendation_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :object_id, :integer, null: false, default: 0
      add :item_id, :integer, null: false, default: 0
      add :item_type, :string, null: false, default: ""
      add :item_value, :integer, null: false, default: 0
      add :item_reducer, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_recommendation_data, [:profile_id])
  end
end
