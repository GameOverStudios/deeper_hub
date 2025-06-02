defmodule Repo.Migrations.CreateBxPersonsData do
  use Ecto.Migration

  def change do
    create table(:bx_persons_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :picture, :integer, null: false
      add :cover, :integer, null: false
      add :cover_data, :string, null: false
      add :fullname, :string, null: false
      add :last_name, :string, null: false
      add :description, :string, null: false
      add :gender, :string
      add :birthday, :date
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
      add :allow_view_to, :string, null: false, default: "3"
      add :allow_post_to, :string, null: false, default: "5"
      add :allow_contact_to, :string, null: false, default: "3"
      add :settings, :string, null: false
      timestamps()
    end
    create index(:bx_persons_data, [:fullname])
  end
end
