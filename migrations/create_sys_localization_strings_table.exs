defmodule Repo.Migrations.CreateSysLocalizationStrings do
  use Ecto.Migration

  def change do
    create table(:sys_localization_strings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :IDKey, :integer, null: false, default: 0
      add :IDLanguage, :integer, null: false, default: 0
      add :String, :string, null: false
      timestamps()
    end
    create index(:sys_localization_strings, [:String])
  end
end
