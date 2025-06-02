defmodule Repo.Migrations.CreateSysRecommendationCriteria do
  use Ecto.Migration

  def change do
    create table(:sys_recommendation_criteria, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :name, :string, null: false, default: ""
      add :source_type, :string, null: false
      add :source, :string, null: false
      add :params, :string, null: false
      add :weight, :float, null: false, default: 0
      add :active, :integer, null: false, default: 1
      timestamps()
    end
    create index(:sys_recommendation_criteria, [:object_id])
  end
end
