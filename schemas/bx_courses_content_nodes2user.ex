defmodule DeeperHub.Schema.BxCoursesContentNodes2user do
  @moduledoc """
  Schema para representação de bx_courses_content_nodes2users no sistema

  Este schema armazena as informações de um bx_courses_content_nodes2user.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_courses_content_nodes2users" do
    field :node_id, :integer, default: 0  # int(11)
    field :profile_id, :integer, default: 0  # int(11)
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_courses_content_nodes2user no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    node_id: integer() | nil,
    profile_id: integer() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_courses_content_nodes2user.

  ## Parâmetros 
    - `bx_courses_content_nodes2user`: Struct do bx_courses_content_nodes2user (pode ser %BxCoursesContentNodes2user{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_courses_content_nodes2user \ %__MODULE__{}, attrs) do
    bx_courses_content_nodes2user
    |> cast(attrs, [:node_id, :profile_id, :date])
  end

  @doc """
  Changeset para atualização de um bx_courses_content_nodes2user existente.

  ## Parâmetros 
    - `bx_courses_content_nodes2user`: Struct do bx_courses_content_nodes2user (%BxCoursesContentNodes2user{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_courses_content_nodes2user \ %__MODULE__{}, attrs) do
    bx_courses_content_nodes2user
    |> cast(attrs, [:node_id, :profile_id, :date])
  end
end
