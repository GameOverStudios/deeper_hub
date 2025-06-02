defmodule Repo.Migrations.CreateBxReputationEvents do
  use Ecto.Migration

  def change do
    create table(:bx_reputation_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :owner_id, :integer, null: false, default: 0
      add :type, :string, null: false, default: ""
      add :action, :string, null: false, default: ""
      add :object_id, :integer, null: false, default: 0
      add :object_owner_id, :integer, null: false, default: 0
      add :points, :integer, null: false, default: 0
      add :date, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_reputation_events, [:owner_id])
    create index(:bx_reputation_events, [:object_id])
  end
end
