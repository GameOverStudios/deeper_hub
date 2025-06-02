defmodule Repo.Migrations.CreateBxFilesMain do
  use Ecto.Migration

  def change do
    create table(:bx_files_main, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :file_id, :integer, null: false
      add :title, :string, null: false
      add :cat, :integer, null: false
      add :desc, :string, null: false
      add :data, :string, null: false
      add :data_processed, :integer, null: false, default: 0
      add :labels, :string, null: false
      add :location, :string, null: false
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
      add :cf, :integer, null: false, default: 1
      add :allow_view_to, :string, null: false, default: "3"
      add :status, :string, null: false, default: "active"
      add :status_admin, :string, null: false, default: "active"
      add :type, :string, null: false, default: "file"
      add :parent_folder_id, :integer, null: false, default: 0
      timestamps()
    end
    create index(:bx_files_main, [:title])
  end
end
