defmodule Repo.Migrations.CreateBxClassesStatuses do
  use Ecto.Migration

  def change do
    create table(:bx_classes_statuses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :class_id, :integer, null: false
      add :student_profile_id, :integer, null: false
      add :viewed, :integer, null: false
      add :replied, :integer, null: false
      add :completed, :integer, null: false
      timestamps()
    end
    create index(:bx_classes_statuses, [:class_id])
  end
end
