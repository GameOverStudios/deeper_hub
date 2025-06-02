defmodule Repo.Migrations.CreateBxOrganizationsData do
  use Ecto.Migration

  def change do
    create table(:bx_organizations_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :picture, :integer, null: false
      add :cover, :integer, null: false
      add :cover_data, :string, null: false
      add :org_name, :string, null: false
      add :org_cat, :integer, null: false
      add :multicat, :string, null: false
      add :org_desc, :string, null: false
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
      add :join_confirmation, :integer, null: false, default: 1
      add :allow_view_to, :string, null: false, default: "3"
      add :allow_post_to, :string, null: false, default: "5"
      add :allow_contact_to, :string, null: false, default: "3"
      add :status, :string, null: false, default: "active"
      add :settings, :string, null: false
      timestamps()
    end
    create index(:bx_organizations_data, [:org_name])
  end
end
