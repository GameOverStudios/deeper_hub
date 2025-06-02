defmodule Repo.Migrations.CreateSysPagesBlocksData do
  use Ecto.Migration

  def change do
    create table(:sys_pages_blocks_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :block_id, :integer, null: false, default: 0
      add :content_id, :integer, null: false, default: 0
      add :content_module, :string, null: false
      add :data, :string, null: false
      timestamps()
    end
    create index(:sys_pages_blocks_data, [:block_id])
  end
end
