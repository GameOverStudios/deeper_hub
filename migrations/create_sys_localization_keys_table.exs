defmodule Repo.Migrations.CreateSysLocalizationKeys do
  use Ecto.Migration

  def change do
    create table(:sys_localization_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ID, :integer, null: false
      add :IDCategory, :integer, null: false, default: 0
      add :Key, :string, null: false, default: ""
      timestamps()
    end
    create index(:sys_localization_keys, [:Key], unique: true)
  end
end
