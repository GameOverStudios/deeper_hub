defmodule Repo.Migrations.CreateBxCoursesContentData do
  use Ecto.Migration

  def change do
    create table(:bx_courses_content_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entry_id, :integer, null: false, default: 0
      add :node_id, :integer, null: false, default: 0
      add :content_type, :string, null: false, default: ""
      add :content_id, :integer, null: false, default: 0
      add :usage, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      timestamps()
    end
  end
end
