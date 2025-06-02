defmodule Repo.Migrations.CreateBxRemindersTypes do
  use Ecto.Migration

  def change do
    create table(:bx_reminders_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false, default: 0
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :name, :string, null: false
      add :title, :string, null: false
      add :text, :string, null: false
      add :link, :string, null: false
      add :when, :string, null: false
      add :show, :integer, null: false, default: 0
      add :notify, :string, null: false
      add :personal, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_reminders_types, [:name], unique: true)
  end
end
