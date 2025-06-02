defmodule DeeperHub.Schema.BxHelpTour do
  @moduledoc """
  Schema para representação de bx_help_tours no sistema

  Este schema armazena as informações de um bx_help_tour.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_help_tours" do
    field :overlay, :boolean  # tinyint(1)
    field :page, :string  # varchar(128)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_help_tour no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    overlay: boolean() | nil,
    page: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_help_tour.

  ## Parâmetros 
    - `bx_help_tour`: Struct do bx_help_tour (pode ser %BxHelpTour{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_help_tour \ %__MODULE__{}, attrs) do
    bx_help_tour
    |> cast(attrs, [:overlay, :page, :order])
    |> validate_required([:overlay, :page, :order])
  end

  @doc """
  Changeset para atualização de um bx_help_tour existente.

  ## Parâmetros 
    - `bx_help_tour`: Struct do bx_help_tour (%BxHelpTour{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_help_tour \ %__MODULE__{}, attrs) do
    bx_help_tour
    |> cast(attrs, [:overlay, :page, :order])
  end
end
