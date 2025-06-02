defmodule Repo.Migrations.CreateBxJobsReportsTrack do
  use Ecto.Migration

  def change do
    create table(:bx_jobs_reports_track, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :author_id, :integer, null: false, default: 0
      add :author_nip, :integer, null: false, default: 0
      add :type, :string, null: false, default: ""
      add :text, :string, null: false, default: "''"
      add :date, :integer, null: false, default: 0
      add :checked_by, :integer, null: false, default: 0
      add :status, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_jobs_reports_track, [:object_id])
  end
end
