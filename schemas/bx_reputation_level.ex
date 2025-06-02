defmodule DeeperHub.Schema.BxReputationLevel do
  @moduledoc """
  Schema para representação de bx_reputation_levels no sistema

  Este schema armazena as informações de um bx_reputation_level.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_reputation_levels" do
    field :name, :string, default: ""  # varchar(32)
    field :title, :string, default: ""  # varchar(64)
    field :icon, :string  # text
    field :points_in, :integer, default: 0  # int(11)
    field :points_out, :integer, default: 0  # int(11)
    field :date, :integer, default: 0  # int(11)
    field :active, :integer, default: 1  # tinyint(4)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_reputation_level no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    title: String.t() | nil,
    icon: String.t() | nil,
    points_in: integer() | nil,
    points_out: integer() | nil,
    date: integer() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_reputation_level.

  ## Parâmetros 
    - `bx_reputation_level`: Struct do bx_reputation_level (pode ser %BxReputationLevel{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_reputation_level \ %__MODULE__{}, attrs) do
    bx_reputation_level
    |> cast(attrs, [:name, :title, :icon, :points_in, :points_out, :date, :active, :order])
    |> validate_required([:name, :title, :icon])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_reputation_level existente.

  ## Parâmetros 
    - `bx_reputation_level`: Struct do bx_reputation_level (%BxReputationLevel{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_reputation_level \ %__MODULE__{}, attrs) do
    bx_reputation_level
    |> cast(attrs, [:name, :title, :icon, :points_in, :points_out, :date, :active, :order])
    |> unique_constraint(:name)
  end
end
