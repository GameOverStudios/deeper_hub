defmodule Repo.Migrations.CreateBxAttendantEvents do
  use Ecto.Migration

  def change do
    create table(:bx_attendant_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :method, :string, null: false
      add :event, :string, null: false
      add :added, :integer
      add :processed, :integer
      add :action, :string, null: false
      add :object_id, :integer
      add :profile_id, :integer
      add :module, :string, null: false
      timestamps()
    end
    create index(:bx_attendant_events, [:action])
    create index(:bx_attendant_events, [:object_id])
  end
end
