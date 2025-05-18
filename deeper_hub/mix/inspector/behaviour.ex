defmodule DeeperHub.Inspector.Behaviour do
  @moduledoc """
  Schema Ecto para relacionar um módulo com um comportamento que ele implementa. 🧩
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "inspector_module_behaviours" do
    field :module_name, :string, primary_key: true
    # Armazena como string
    field :behaviour_module, :string, primary_key: true

    # belongs_to :module, DeeperHub.Inspector.Module, foreign_key: :module_name, references: :name, type: :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(behaviour_struct, attrs) do
    behaviour_struct
    |> cast(attrs, [:module_name, :behaviour_module])
    |> validate_required([:module_name, :behaviour_module])
  end
end
