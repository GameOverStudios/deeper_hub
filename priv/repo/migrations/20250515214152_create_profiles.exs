defmodule Deeper_Hub.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :profile_picture, :string
      add :bio, :string
      add :website, :string

      timestamps()
    end

    create index(:profiles, [:user_id])
  end
end
