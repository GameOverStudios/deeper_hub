defmodule DeeperHub.Schema.BxAdsSource do
  @moduledoc """
  Schema para representação de bx_ads_sources no sistema

  Este schema armazena as informações de um bx_ads_source.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_ads_sources" do
    field :name, :string, default: ""  # varchar(64)
    field :caption, :string, default: ""  # varchar(128)
    field :description, :string, default: ""  # varchar(128)
    field :option_prefix, :string, default: ""  # varchar(32)
    field :active, :integer, default: 0  # tinyint(4)
    field :order, :integer, default: 0  # tinyint(4)
    field :class_name, :string, default: ""  # varchar(128)
    field :class_file, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_ads_source no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    caption: String.t() | nil,
    description: String.t() | nil,
    option_prefix: String.t() | nil,
    active: integer() | nil,
    order: integer() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_ads_source.

  ## Parâmetros 
    - `bx_ads_source`: Struct do bx_ads_source (pode ser %BxAdsSource{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_ads_source \ %__MODULE__{}, attrs) do
    bx_ads_source
    |> cast(attrs, [:name, :caption, :description, :option_prefix, :active, :order, :class_name, :class_file])
    |> validate_required([:name, :caption, :description, :option_prefix, :class_name, :class_file])
  end

  @doc """
  Changeset para atualização de um bx_ads_source existente.

  ## Parâmetros 
    - `bx_ads_source`: Struct do bx_ads_source (%BxAdsSource{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_ads_source \ %__MODULE__{}, attrs) do
    bx_ads_source
    |> cast(attrs, [:name, :caption, :description, :option_prefix, :active, :order, :class_name, :class_file])
  end
end
