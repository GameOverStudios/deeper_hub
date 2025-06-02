defmodule Repo.Migrations.CreateBxClassesLinks2content do
  use Ecto.Migration

  def change do
    create table(:bx_classes_links2content, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content_id, :integer, null: false, default: 0
      add :link_id, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_classes_links2content, [:link_id])
  end
end
