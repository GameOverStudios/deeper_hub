defmodule Repo.Migrations.CreateBxCoursesFans do
  use Ecto.Migration

  def change do
    create table(:bx_courses_fans, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :initiator, :integer, null: false
      add :content, :integer, null: false
      add :mutual, :integer, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:bx_courses_fans, [:initiator])
    create index(:bx_courses_fans, [:content])
  end
end
