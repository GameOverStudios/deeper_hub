defmodule Repo.Migrations.CreateBxCnlContent do
  use Ecto.Migration

  def change do
    create table(:bx_cnl_content, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content_id, :integer, null: false
      add :cnl_id, :integer, null: false
      add :author_id, :integer, null: false
      add :module_name, :string, null: false
      add :date, :integer, null: false, default: 0
      timestamps()
    end
  end
end
