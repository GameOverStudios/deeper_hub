defmodule Repo.Migrations.CreateSysObjectsVote do
  use Ecto.Migration

  def change do
    create table(:sys_objects_vote, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ID, :integer, null: false
      add :Name, :string, null: false, default: ""
      add :Module, :string, null: false, default: ""
      add :TableMain, :string, null: false, default: ""
      add :TableTrack, :string, null: false, default: ""
      add :PostTimeout, :integer, null: false, default: 0
      add :MinValue, :integer, null: false, default: 1
      add :MaxValue, :integer, null: false, default: 5
      add :Pruning, :integer, null: false, default: 31536000
      add :IsUndo, :boolean, null: false, default: false
      add :IsOn, :boolean, null: false, default: true
      add :TriggerTable, :string, null: false, default: ""
      add :TriggerFieldId, :string, null: false, default: ""
      add :TriggerFieldAuthor, :string, null: false, default: ""
      add :TriggerFieldRate, :string, null: false, default: ""
      add :TriggerFieldRateCount, :string, null: false, default: ""
      add :ClassName, :string, null: false, default: ""
      add :ClassFile, :string, null: false, default: ""
      timestamps()
    end
  end
end
