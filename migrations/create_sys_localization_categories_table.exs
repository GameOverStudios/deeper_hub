defmodule Repo.Migrations.CreateSysLocalizationCategories do
  use Ecto.Migration

  def change do
    create table(:sys_localization_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ID, :integer, null: false
      add :Name, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_localization_categories, [:Name], unique: true)
  end
end
