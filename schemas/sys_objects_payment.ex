defmodule DeeperHub.Schema.SysObjectsPayment do
  @moduledoc """
  Schema para representação de sys_objects_payments no sistema

  Este schema armazena as informações de um sys_objects_payment.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_payments" do
    field :object, :string  # varchar(32)
    field :title, :string  # varchar(255)
    field :uri, :string, default: ""  # varchar(32)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_payment no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    title: String.t() | nil,
    uri: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_payment.

  ## Parâmetros 
    - `sys_objects_payment`: Struct do sys_objects_payment (pode ser %SysObjectsPayment{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_payment \ %__MODULE__{}, attrs) do
    sys_objects_payment
    |> cast(attrs, [:object, :title, :uri])
    |> validate_required([:object, :title, :uri])
    |> unique_constraint(:object)
    |> unique_constraint(:uri)
  end

  @doc """
  Changeset para atualização de um sys_objects_payment existente.

  ## Parâmetros 
    - `sys_objects_payment`: Struct do sys_objects_payment (%SysObjectsPayment{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_payment \ %__MODULE__{}, attrs) do
    sys_objects_payment
    |> cast(attrs, [:object, :title, :uri])
    |> unique_constraint(:object)
    |> unique_constraint(:uri)
  end
end
