defmodule Repo.Migrations.CreateBxRemindersEntries do
  use Ecto.Migration

  def change do
    create table(:bx_reminders_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type_id, :integer, null: false, default: 0
      add :rmd_pid, :integer, null: false, default: 0
      add :cnt_pid, :integer, null: false, default: 0
      add :params, :string, null: false, default: "''"
      add :notified, :string, null: false, default: "''"
      add :active, :integer, null: false, default: 0
      add :visible, :integer, null: false, default: 0
      add :added, :integer, null: false
      add :expired, :integer, null: false
      timestamps()
    end
  end
end
