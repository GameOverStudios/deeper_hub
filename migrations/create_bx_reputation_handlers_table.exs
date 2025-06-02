defmodule Repo.Migrations.CreateBxReputationHandlers do
  use Ecto.Migration

  def change do
    create table(:bx_reputation_handlers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group, :string, null: false, default: ""
      add :type, :string, null: false, default: "insert"
      add :alert_unit, :string, null: false, default: ""
      add :alert_action, :string, null: false, default: ""
      add :points_active, :integer, null: false, default: 0
      add :points_passive, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 1
      timestamps()
    end
    create index(:bx_reputation_handlers, [:alert_unit])
  end
end
