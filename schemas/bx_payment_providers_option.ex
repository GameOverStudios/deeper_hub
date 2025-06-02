defmodule DeeperHub.Schema.BxPaymentProvidersOption do
  @moduledoc """
  Schema para representação de bx_payment_providers_options no sistema

  Este schema armazena as informações de um bx_payment_providers_option.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_providers_options" do
    field :provider_id, :string, default: ""  # varchar(64)
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
  Tipo que representa um bx_payment_providers_option no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    provider_id: String.t() | nil,
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
  Changeset para criação de um novo bx_payment_providers_option.

  ## Parâmetros 
    - `bx_payment_providers_option`: Struct do bx_payment_providers_option (pode ser %BxPaymentProvidersOption{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_providers_option \ %__MODULE__{}, attrs) do
    bx_payment_providers_option
    |> cast(attrs, [:provider_id, :name, :type, :caption, :description, :extra, :check_type, :check_params, :check_error, :order])
    |> validate_required([:provider_id, :name, :caption, :extra, :check_type, :check_params, :check_error])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_payment_providers_option existente.

  ## Parâmetros 
    - `bx_payment_providers_option`: Struct do bx_payment_providers_option (%BxPaymentProvidersOption{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_providers_option \ %__MODULE__{}, attrs) do
    bx_payment_providers_option
    |> cast(attrs, [:provider_id, :name, :type, :caption, :description, :extra, :check_type, :check_params, :check_error, :order])
    |> unique_constraint(:name)
  end
end
