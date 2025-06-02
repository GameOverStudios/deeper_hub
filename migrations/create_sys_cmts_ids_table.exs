defmodule Repo.Migrations.CreateSysCmtsIds do
  use Ecto.Migration

  def change do
    create table(:sys_cmts_ids, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :system_id, :integer, null: false, default: 0
      add :cmt_id, :integer, null: false, default: 0
      add :author_id, :integer, null: false, default: 0
      add :rate, :float, null: false, default: 0
      add :votes, :integer, null: false, default: 0
      add :rrate, :float, null: false, default: 0
      add :rvotes, :integer, null: false, default: 0
      add :score, :integer, null: false, default: 0
      add :sc_up, :integer, null: false, default: 0
      add :sc_down, :integer, null: false, default: 0
      add :reports, :integer, null: false, default: 0
      add :status_admin, :string, null: false, default: "active"
      timestamps()
    end
    create index(:sys_cmts_ids, [:system_id])
  end
end
