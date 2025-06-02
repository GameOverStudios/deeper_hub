defmodule DeeperHub.Schema.BxHelpToursItem do
  @moduledoc """
  Schema para representação de bx_help_tours_items no sistema

  Este schema armazena as informações de um bx_help_tours_item.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_help_tours_items" do
    field :tour, :integer  # int(11)
    field :name, :string  # varchar(255)
    field :element, :string  # varchar(255)
    field :arrow, Ecto.Enum, values: [:auto, :auto-start, :auto-end, :top, :top-start, :top-end, :bottom, :bottom-start, :bottom-end, :right, :right-start, :right-end, :left, :left-start, :left-end]  # enum('auto','auto-start','auto-end','top','top-start','top-end','bottom','bottom-start','bottom-end','right','right-start','right-end','left','left-start','left-end')
    field :title, :string  # varchar(128)
    field :text, :string  # varchar(128)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_help_tours_item no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    tour: integer() | nil,
    name: String.t() | nil,
    element: String.t() | nil,
    arrow: :auto | :auto-start | :auto-end | :top | :top-start | :top-end | :bottom | :bottom-start | :bottom-end | :right | :right-start | :right-end | :left | :left-start | :left-end | nil,
    title: String.t() | nil,
    text: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_help_tours_item.

  ## Parâmetros 
    - `bx_help_tours_item`: Struct do bx_help_tours_item (pode ser %BxHelpToursItem{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_help_tours_item \ %__MODULE__{}, attrs) do
    bx_help_tours_item
    |> cast(attrs, [:tour, :name, :element, :arrow, :title, :text, :order])
    |> validate_required([:tour, :name, :element, :title, :text, :order])
  end

  @doc """
  Changeset para atualização de um bx_help_tours_item existente.

  ## Parâmetros 
    - `bx_help_tours_item`: Struct do bx_help_tours_item (%BxHelpToursItem{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_help_tours_item \ %__MODULE__{}, attrs) do
    bx_help_tours_item
    |> cast(attrs, [:tour, :name, :element, :arrow, :title, :text, :order])
  end
end
