defmodule DeeperHub.Schema.BxCoursesContentNode do
  @moduledoc """
  Schema para representação de bx_courses_content_nodes no sistema

  Este schema armazena as informações de um bx_courses_content_node.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_courses_content_nodes" do
    field :entry_id, :integer, default: 0  # int(11)
    field :title, :string, default: ""  # varchar(255)
    field :text, :string  # text
    field :passing, :integer, default: 0  # tinyint(4)
    field :counters, :string  # text
    field :added, :integer  # int(11)
    field :status, Ecto.Enum, values: [:active, :hidden], default: "active"  # enum('active','hidden')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_courses_content_node no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    entry_id: integer() | nil,
    title: String.t() | nil,
    text: String.t() | nil,
    passing: integer() | nil,
    counters: String.t() | nil,
    added: integer() | nil,
    status: :active | :hidden | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_courses_content_node.

  ## Parâmetros 
    - `bx_courses_content_node`: Struct do bx_courses_content_node (pode ser %BxCoursesContentNode{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_courses_content_node \ %__MODULE__{}, attrs) do
    bx_courses_content_node
    |> cast(attrs, [:entry_id, :title, :text, :passing, :counters, :added, :status])
    |> validate_required([:title, :text, :counters, :added])
  end

  @doc """
  Changeset para atualização de um bx_courses_content_node existente.

  ## Parâmetros 
    - `bx_courses_content_node`: Struct do bx_courses_content_node (%BxCoursesContentNode{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_courses_content_node \ %__MODULE__{}, attrs) do
    bx_courses_content_node
    |> cast(attrs, [:entry_id, :title, :text, :passing, :counters, :added, :status])
  end
end
