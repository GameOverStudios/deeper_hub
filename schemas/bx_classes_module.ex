defmodule DeeperHub.Schema.BxClassesModule do
  @moduledoc """
  Schema para representação de bx_classes_modules no sistema

  Este schema armazena as informações de um bx_classes_module.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_classes_modules" do
    field :profile_id, :integer  # int(10) unsigned
    field :module_title, :string  # varchar(255)
    field :author, :integer  # int(11)
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_classes_module no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    module_title: String.t() | nil,
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_classes_module.

  ## Parâmetros 
    - `bx_classes_module`: Struct do bx_classes_module (pode ser %BxClassesModule{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_classes_module \ %__MODULE__{}, attrs) do
    bx_classes_module
    |> cast(attrs, [:profile_id, :module_title, :author, :added, :changed, :order])
    |> validate_required([:profile_id, :module_title, :author, :added, :changed, :order])
  end

  @doc """
  Changeset para atualização de um bx_classes_module existente.

  ## Parâmetros 
    - `bx_classes_module`: Struct do bx_classes_module (%BxClassesModule{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_classes_module \ %__MODULE__{}, attrs) do
    bx_classes_module
    |> cast(attrs, [:profile_id, :module_title, :author, :added, :changed, :order])
  end
end
