defmodule Repo.Migrations.CreateBxPaymentProviders do
  use Ecto.Migration

  def change do
    create table(:bx_payment_providers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, default: ""
      add :caption, :string, null: false, default: ""
      add :description, :string, null: false, default: ""
      add :option_prefix, :string, null: false, default: ""
      add :for_visitor, :integer, null: false, default: 0
      add :for_owner_only, :integer, null: false, default: 0
      add :for_single, :integer, null: false, default: 0
      add :for_recurring, :integer, null: false, default: 0
      add :single_seller, :integer, null: false, default: 0
      add :time_tracker, :integer, null: false, default: 0
      add :active, :integer, null: false, default: 0
      add :order, :integer, null: false, default: 0
      add :class_name, :string, null: false, default: ""
      add :class_file, :string, null: false, default: ""
      timestamps()
    end
  end
end
