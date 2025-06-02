defmodule Repo.Migrations.CreateSysLocalizationLanguages do
  use Ecto.Migration

  def change do
    create table(:sys_localization_languages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ID, :integer, null: false
      add :Name, :string, null: false, default: ""
      add :Flag, :string, null: false, default: ""
      add :Title, :string, null: false, default: ""
      add :Direction, :string, null: false, default: "LTR"
      add :LanguageCountry, :string, null: false
      add :Enabled, :boolean, null: false, default: false
      timestamps()
    end
    create index(:sys_localization_languages, [:Name], unique: true)
  end
end
