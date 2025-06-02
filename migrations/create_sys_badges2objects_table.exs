defmodule Repo.Migrations.CreateSysBadges2objects do
  use Ecto.Migration

  def change do
    create table(:sys_badges2objects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :badge_id, :integer, null: false
      add :object_id, :integer, null: false
      add :module, :string, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:sys_badges2objects, [:object_id])
  end
end
