defmodule Repo.Migrations.CreateBxAntispamBlockLog do
  use Ecto.Migration

  def change do
    create table(:bx_antispam_block_log, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ip, :integer, null: false
      add :profile_id, :integer, null: false
      add :type, :string, null: false
      add :extra, :string, null: false
      add :added, :integer, null: false
      timestamps()
    end
    create index(:bx_antispam_block_log, [:ip])
    create index(:bx_antispam_block_log, [:profile_id])
  end
end
