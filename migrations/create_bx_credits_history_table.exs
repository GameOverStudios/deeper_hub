defmodule Repo.Migrations.CreateBxCreditsHistory do
  use Ecto.Migration

  def change do
    create table(:bx_credits_history, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :first_pid, :integer, null: false, default: 0
      add :second_pid, :integer, null: false, default: 0
      add :amount, :float, null: false, default: 0
      add :type, :string, null: false, default: ""
      add :direction, :string, null: false, default: "in"
      add :order, :string, null: false, default: ""
      add :data, :string, null: false, default: "''"
      add :info, :string, null: false, default: ""
      add :date, :integer, null: false, default: 0
      add :cleared, :integer, null: false, default: 0
      timestamps()
    end
  end
end
