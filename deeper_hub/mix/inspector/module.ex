defmodule Deeper_Hub.Inspector.Module do
  @moduledoc """
  Schema Ecto para informações de um módulo inspecionado. 📜
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:name, :string, autogenerate: false}
  @derive {Jason.Encoder, only: [:name, :moduledoc, :struct_definition, :behaviours]}
  schema "inspector_modules" do
    field :moduledoc, :string
    # Armazena o inspect() da struct
    field :struct_definition, :string

    # Relacionamentos (definidos depois)
    # has_many :functions, Deeper_Hub.Inspector.Function, foreign_key: :module_name, references: :name
    # has_many :typespecs, Deeper_Hub.Inspector.TypeSpec, foreign_key: :module_name, references: :name
    has_many :behaviours, Deeper_Hub.Inspector.Behaviour,
      foreign_key: :module_name,
      references: :name

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(module_struct, attrs) do
    module_struct
    |> cast(attrs, [:name, :moduledoc, :struct_definition])
    |> validate_required([:name])

    # Adicionar unique_constraint se necessário ao inserir
  end
end
