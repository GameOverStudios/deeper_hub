defmodule Repo.Migrations.CreateBxCoursesContentNodes do
  use Ecto.Migration

  def change do
    create table(:bx_courses_content_nodes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entry_id, :integer, null: false, default: 0
      add :title, :string, null: false, default: ""
      add :text, :string, null: false
      add :passing, :integer, null: false, default: 0
      add :counters, :string, null: false
      add :added, :integer, null: false
      add :status, :string, null: false, default: "active"
      timestamps()
    end
  end
end
