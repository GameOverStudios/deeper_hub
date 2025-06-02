defmodule Repo.Migrations.CreateBxGroupsData do
  use Ecto.Migration

  def change do
    create table(:bx_groups_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :picture, :integer, null: false
      add :cover, :integer, null: false
      add :cover_data, :string, null: false
      add :group_name, :string, null: false
      add :group_cat, :integer, null: false
      add :group_desc, :string, null: false
      add :labels, :string, null: false
      add :location, :string, null: false
      add :members, :integer, null: false, default: 0
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
      add :join_confirmation, :integer, null: false, default: 0
      add :allow_view_to, :string, null: false, default: "3"
      add :allow_post_to, :string, null: false, default: "3"
      add :status, :string, null: false, default: "active"
      add :status_admin, :string, null: false, default: "active"
      timestamps()
    end
    create index(:bx_groups_data, [:group_name])
  end
end
