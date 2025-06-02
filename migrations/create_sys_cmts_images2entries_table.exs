defmodule Repo.Migrations.CreateSysCmtsImages2entries do
  use Ecto.Migration

  def change do
    create table(:sys_cmts_images2entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :system_id, :integer, null: false, default: 0
      add :cmt_id, :integer, null: false, default: 0
      add :image_id, :integer, null: false, default: 0
      timestamps()
    end
    create index(:sys_cmts_images2entries, [:system_id])
  end
end
