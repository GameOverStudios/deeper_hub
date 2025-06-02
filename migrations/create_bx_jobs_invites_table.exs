defmodule Repo.Migrations.CreateBxJobsInvites do
  use Ecto.Migration

  def change do
    create table(:bx_jobs_invites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string, null: false, default: "0"
      add :group_profile_id, :integer, null: false, default: 0
      add :author_profile_id, :integer, null: false, default: 0
      add :invited_profile_id, :integer, null: false, default: 0
      add :added, :integer, null: false, default: 0
      timestamps()
    end
  end
end
