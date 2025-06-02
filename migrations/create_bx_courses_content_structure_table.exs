defmodule Repo.Migrations.CreateBxCoursesContentStructure do
  use Ecto.Migration

  def change do
    create table(:bx_courses_content_structure, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entry_id, :integer, null: false, default: 0
      add :parent_id, :integer, null: false, default: 0
      add :node_id, :integer, null: false, default: 0
      add :level, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      add :cn_l2, :integer, null: false, default: 0
      add :cn_l3, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_courses_content_structure, [:node_id], unique: true)
  end
end
