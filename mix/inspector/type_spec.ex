defmodule DeeperHub.Inspector.TypeSpec do
  @moduledoc """
  Schema Ecto para informações de typespecs (@type, @opaque, @spec, @callback). 📋
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :string
  schema "inspector_typespecs" do
    field :module_name, :string
    # "type", "opaque", "spec", "callback", "macrocallback"
    field :kind, :string
    # Nome do tipo ou da função/callback
    field :name, :string
    field :arity, :integer
    # Representação textual da definição/spec
    field :definition, :string

    # belongs_to :module, DeeperHub.Inspector.Module, foreign_key: :module_name, references: :name, type: :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(typespec_struct, attrs) do
    typespec_struct
    |> cast(attrs, [:module_name, :kind, :name, :arity, :definition])
    |> validate_required([:module_name, :kind, :name, :arity, :definition])
  end
end
