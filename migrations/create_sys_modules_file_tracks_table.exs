defmodule Repo.Migrations.CreateSysModulesFileTracks do
  use Ecto.Migration

  def change do
    create table(:sys_modules_file_tracks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module_id, :integer, null: false, default: 0
      add :file, :string, null: false, default: ""
      add :hash, :string, null: false, default: ""
      timestamps()
    end
  end
end
