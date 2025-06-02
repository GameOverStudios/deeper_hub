defmodule Repo.Migrations.CreateBxPersonsSkills do
  use Ecto.Migration

  def change do
    create table(:bx_persons_skills, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :skill_id, :integer, null: false
      add :skill_name, :string
      add :content_id, :integer, null: false
      timestamps()
    end
    create index(:bx_persons_skills, [:content_id])
  end
end
