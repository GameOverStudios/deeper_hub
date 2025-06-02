defmodule DeeperHub.Schema.BxAdsSourcesOption do
  @moduledoc """
  Schema para representação de bx_ads_sources_options no sistema

  Este schema armazena as informações de um bx_ads_sources_option.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_ads_sources_options" do
    field :source_id, :string, default: ""  # varchar(64)
    field :name, :string, default: ""  # varchar(64)
    field :type, :string, default: "text"  # varchar(64)
    field :caption, :string, default: ""  # varchar(255)
    field :description, :string, default: "''"  # text
    field :extra, :string, default: ""  # varchar(255)
    field :check_type, :string, default: ""  # varchar(64)
    field :check_params, :string, default: ""  # varchar(128)
    field :check_error, :string, default: ""  # varchar(128)
    field :order, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_ads_sources_option no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    source_id: String.t() | nil,
    name: String.t() | nil,
    type: String.t() | nil,
    caption: String.t() | nil,
    description: String.t() | nil,
    extra: String.t() | nil,
    check_type: String.t() | nil,
    check_params: String.t() | nil,
    check_error: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_ads_sources_option.

  ## Parâmetros 
    - `bx_ads_sources_option`: Struct do bx_ads_sources_option (pode ser %BxAdsSourcesOption{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_ads_sources_option \ %__MODULE__{}, attrs) do
    bx_ads_sources_option
    |> cast(attrs, [:source_id, :name, :type, :caption, :description, :extra, :check_type, :check_params, :check_error, :order])
    |> validate_required([:source_id, :name, :caption, :extra, :check_type, :check_params, :check_error])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_ads_sources_option existente.

  ## Parâmetros 
    - `bx_ads_sources_option`: Struct do bx_ads_sources_option (%BxAdsSourcesOption{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_ads_sources_option \ %__MODULE__{}, attrs) do
    bx_ads_sources_option
    |> cast(attrs, [:source_id, :name, :type, :caption, :description, :extra, :check_type, :check_params, :check_error, :order])
    |> unique_constraint(:name)
  end
end
