defmodule Repo.Migrations.CreateBxCoursesContentNodes2users do
  use Ecto.Migration

  def change do
    create table(:bx_courses_content_nodes2users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :node_id, :integer, null: false, default: 0
      add :profile_id, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_courses_content_nodes2users, [:node_id])
  end
end
