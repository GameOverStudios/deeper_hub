defmodule Repo.Migrations.CreateBxTasksTasks do
  use Ecto.Migration

  def change do
    create table(:bx_tasks_tasks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :published, :integer, null: false
      add :thumb, :integer, null: false
      add :title, :string, null: false
      add :cat, :integer, null: false
      add :multicat, :string, null: false
      add :text, :string, null: false
      add :labels, :string, null: false
      add :views, :integer, null: false, default: 0
      add :rate, :float, null: false, default: 0
      add :votes, :integer, null: false, default: 0
      add :rrate, :float, null: false, default: 0
      add :rvotes, :integer, null: false, default: 0
      add :score, :integer, null: false, default: 0
      add :sc_up, :integer, null: false, default: 0
      add :sc_down, :integer, null: false, default: 0
      add :favorites, :integer, null: false, default: 0
      add :comments, :integer, null: false, default: 0
      add :reports, :integer, null: false, default: 0
      add :featured, :integer, null: false, default: 0
      add :due_date, :integer, null: false
      add :tasks_list, :integer, null: false
      add :completed, :integer, null: false, default: 0
      add :expired, :integer, null: false, default: 0
      add :cf, :integer, null: false, default: 1
      add :allow_view_to, :string, null: false, default: "3"
      add :allow_comments, :integer, null: false, default: 1
      add :status, :string, null: false, default: "active"
      add :status_admin, :string, null: false, default: "active"
      timestamps()
    end
    create index(:bx_tasks_tasks, [:title])
  end
end
