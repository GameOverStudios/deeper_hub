defmodule DeeperHub.Schema.BxCoursesContentData do
  @moduledoc """
  Schema para representação de bx_courses_content_datas no sistema

  Este schema armazena as informações de um bx_courses_content_data.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_courses_content_data" do
    field :entry_id, :integer, default: 0  # int(11)
    field :node_id, :integer, default: 0  # int(11)
    field :content_type, :string, default: ""  # varchar(32)
    field :content_id, :integer, default: 0  # int(11)
    field :usage, :integer, default: 0  # tinyint(4)
    field :added, :integer, default: 0  # int(11)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_courses_content_data no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    entry_id: integer() | nil,
    node_id: integer() | nil,
    content_type: String.t() | nil,
    content_id: integer() | nil,
    usage: integer() | nil,
    added: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_courses_content_data.

  ## Parâmetros 
    - `bx_courses_content_data`: Struct do bx_courses_content_data (pode ser %BxCoursesContentData{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_courses_content_data \ %__MODULE__{}, attrs) do
    bx_courses_content_data
    |> cast(attrs, [:entry_id, :node_id, :content_type, :content_id, :usage, :added, :order])
    |> validate_required([:content_type])
  end

  @doc """
  Changeset para atualização de um bx_courses_content_data existente.

  ## Parâmetros 
    - `bx_courses_content_data`: Struct do bx_courses_content_data (%BxCoursesContentData{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_courses_content_data \ %__MODULE__{}, attrs) do
    bx_courses_content_data
    |> cast(attrs, [:entry_id, :node_id, :content_type, :content_id, :usage, :added, :order])
  end
end
