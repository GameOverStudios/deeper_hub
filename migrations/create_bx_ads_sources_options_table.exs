defmodule Repo.Migrations.CreateBxAdsSourcesOptions do
  use Ecto.Migration

  def change do
    create table(:bx_ads_sources_options, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source_id, :string, null: false, default: ""
      add :name, :string, null: false, default: ""
      add :type, :string, null: false, default: "text"
      add :caption, :string, null: false, default: ""
      add :description, :string, null: false, default: "''"
      add :extra, :string, null: false, default: ""
      add :check_type, :string, null: false, default: ""
      add :check_params, :string, null: false, default: ""
      add :check_error, :string, null: false, default: ""
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_ads_sources_options, [:name], unique: true)
  end
end
