defmodule Repo.Migrations.CreateSysProfilesTrack do
  use Ecto.Migration

  def change do
    create table(:sys_profiles_track, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false, default: 0
      add :action, :string, null: false, default: ""
      add :date, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_profiles_track, [:profile_id])
  end
end
