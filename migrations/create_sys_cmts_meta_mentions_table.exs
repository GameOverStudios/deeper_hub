defmodule Repo.Migrations.CreateSysCmtsMetaMentions do
  use Ecto.Migration

  def change do
    create table(:sys_cmts_meta_mentions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :integer, null: false
      add :profile_id, :integer, null: false
      timestamps()
    end
    create index(:sys_cmts_meta_mentions, [:object_id])
    create index(:sys_cmts_meta_mentions, [:profile_id])
  end
end
