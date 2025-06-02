defmodule Repo.Migrations.CreateBxClassesLinks do
  use Ecto.Migration

  def change do
    create table(:bx_classes_links, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, :integer, null: false
      add :media_id, :integer, null: false, default: 0
      add :url, :string, null: false
      add :title, :string, null: false
      add :text, :string, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:bx_classes_links, [:profile_id])
  end
end
