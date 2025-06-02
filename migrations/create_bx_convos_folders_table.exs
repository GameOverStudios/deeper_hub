defmodule Repo.Migrations.CreateBxConvosFolders do
  use Ecto.Migration

  def change do
    create table(:bx_convos_folders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :name, :string, null: false, default: ""
      timestamps()
    end
    create index(:bx_convos_folders, [:author])
  end
end
