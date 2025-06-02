defmodule Repo.Migrations.CreateBxCnlData do
  use Ecto.Migration

  def change do
    create table(:bx_cnl_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :integer, null: false
      add :added, :integer, null: false
      add :changed, :integer, null: false
      add :picture, :integer, null: false
      add :cover, :integer, null: false
      add :cover_data, :string, null: false
      add :channel_name, :string, null: false
      add :lc_id, :integer, null: false, default: 0
      add :lc_date, :integer, null: false, default: 0
      add :contents, :integer, null: false, default: 0
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
      add :allow_view_to, :string, default: "3"
      add :status, :string, null: false, default: "active"
      add :status_admin, :string, null: false, default: "active"
      timestamps()
    end
    create index(:bx_cnl_data, [:channel_name], unique: true)
  end
end
