defmodule Repo.Migrations.CreateBxContactEntries do
  use Ecto.Migration

  def change do
    create table(:bx_contact_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :email, :string, null: false
      add :subject, :string, null: false
      add :body, :string, null: false
      add :uri, :string, null: false
      add :date, :integer, null: false, default: 0
      timestamps()
    end
  end
end
