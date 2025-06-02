defmodule Repo.Migrations.CreateBxAdsSources do
  use Ecto.Migration

  def change do
    create table(:bx_ads_sources, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :caption, :string, null: false, default: ""
      add :description, :string, null: false, default: ""
      add :option_prefix, :string, null: false, default: ""
      add :active, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
  end
end
