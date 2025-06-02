defmodule DeeperHub.Schema.BxCoursesContentStructure do
  @moduledoc """
  Schema para representação de bx_courses_content_structures no sistema

  Este schema armazena as informações de um bx_courses_content_structure.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_courses_content_structure" do
    field :entry_id, :integer, default: 0  # int(11)
    field :parent_id, :integer, default: 0  # int(11)
    field :node_id, :integer, default: 0  # int(11)
    field :level, :integer, default: 0  # tinyint(4)
    field :order, :integer, default: 0  # int(11)
    field :cn_l2, :integer, default: 0  # int(11)
    field :cn_l3, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_courses_content_structure no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    entry_id: integer() | nil,
    parent_id: integer() | nil,
    node_id: integer() | nil,
    level: integer() | nil,
    order: integer() | nil,
    cn_l2: integer() | nil,
    cn_l3: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_courses_content_structure.

  ## Parâmetros 
    - `bx_courses_content_structure`: Struct do bx_courses_content_structure (pode ser %BxCoursesContentStructure{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_courses_content_structure \ %__MODULE__{}, attrs) do
    bx_courses_content_structure
    |> cast(attrs, [:entry_id, :parent_id, :node_id, :level, :order, :cn_l2, :cn_l3])
    |> unique_constraint(:node_id)
  end

  @doc """
  Changeset para atualização de um bx_courses_content_structure existente.

  ## Parâmetros 
    - `bx_courses_content_structure`: Struct do bx_courses_content_structure (%BxCoursesContentStructure{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_courses_content_structure \ %__MODULE__{}, attrs) do
    bx_courses_content_structure
    |> cast(attrs, [:entry_id, :parent_id, :node_id, :level, :order, :cn_l2, :cn_l3])
    |> unique_constraint(:node_id)
  end
end
