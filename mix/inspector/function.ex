defmodule Deeper_Hub.Inspector.Function do
  @moduledoc """
  Schema Ecto para informações de uma função documentada. 🔧
  """
  use Ecto.Schema
  import Ecto.Changeset

  # Chave primária composta: nome do módulo, nome da função, aridade
  @primary_key false
  schema "inspector_functions" do
    field :module_name, :string, primary_key: true
    # Armazena como string para compatibilidade DB
    field :name, :string, primary_key: true
    field :arity, :integer, primary_key: true
    field :doc, :string
    field :signature, :string

    # belongs_to :module, Deeper_Hub.Inspector.Module, foreign_key: :module_name, references: :name, type: :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(function_struct, attrs) do
    function_struct
    |> cast(attrs, [:module_name, :name, :arity, :doc, :signature])
    |> validate_required([:module_name, :name, :arity])
  end
end
