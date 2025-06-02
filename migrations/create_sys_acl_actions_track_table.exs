defmodule Repo.Migrations.CreateSysAclActionsTrack do
  use Ecto.Migration

  def change do
    create table(:sys_acl_actions_track, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :IDAction, :integer, null: false, default: 0
      add :IDMember, :integer, null: false, default: 0
      add :ActionsLeft, :integer, null: false, default: 0
      add :ValidSince, :naive_datetime
      timestamps()
    end
  end
end
