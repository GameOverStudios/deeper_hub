defmodule DeeperHub.Schema.BxPaymentProvider do
  @moduledoc """
  Schema para representação de bx_payment_providers no sistema

  Este schema armazena as informações de um bx_payment_provider.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_payment_providers" do
    field :name, :string, default: ""  # varchar(64)
    field :caption, :string, default: ""  # varchar(128)
    field :description, :string, default: ""  # varchar(128)
    field :option_prefix, :string, default: ""  # varchar(32)
    field :for_visitor, :integer, default: 0  # tinyint(4)
    field :for_owner_only, :integer, default: 0  # tinyint(4)
    field :for_single, :integer, default: 0  # tinyint(4)
    field :for_recurring, :integer, default: 0  # tinyint(4)
    field :single_seller, :integer, default: 0  # tinyint(4)
    field :time_tracker, :integer, default: 0  # tinyint(4)
    field :active, :integer, default: 0  # tinyint(4)
    field :order, :integer, default: 0  # tinyint(4)
    field :class_name, :string, default: ""  # varchar(128)
    field :class_file, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_payment_provider no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    caption: String.t() | nil,
    description: String.t() | nil,
    option_prefix: String.t() | nil,
    for_visitor: integer() | nil,
    for_owner_only: integer() | nil,
    for_single: integer() | nil,
    for_recurring: integer() | nil,
    single_seller: integer() | nil,
    time_tracker: integer() | nil,
    active: integer() | nil,
    order: integer() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_payment_provider.

  ## Parâmetros 
    - `bx_payment_provider`: Struct do bx_payment_provider (pode ser %BxPaymentProvider{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_payment_provider \ %__MODULE__{}, attrs) do
    bx_payment_provider
    |> cast(attrs, [:name, :caption, :description, :option_prefix, :for_visitor, :for_owner_only, :for_single, :for_recurring, :single_seller, :time_tracker, :active, :order, :class_name, :class_file])
    |> validate_required([:name, :caption, :description, :option_prefix, :class_name, :class_file])
  end

  @doc """
  Changeset para atualização de um bx_payment_provider existente.

  ## Parâmetros 
    - `bx_payment_provider`: Struct do bx_payment_provider (%BxPaymentProvider{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_payment_provider \ %__MODULE__{}, attrs) do
    bx_payment_provider
    |> cast(attrs, [:name, :caption, :description, :option_prefix, :for_visitor, :for_owner_only, :for_single, :for_recurring, :single_seller, :time_tracker, :active, :order, :class_name, :class_file])
  end
end
