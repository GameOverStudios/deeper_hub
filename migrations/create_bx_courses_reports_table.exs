defmodule Repo.Migrations.CreateBxCoursesReports do
  use Ecto.Migration

  def change do
    create table(:bx_courses_reports, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false, default: 0
      add :count, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_courses_reports, [:object_id], unique: true)
  end
end
