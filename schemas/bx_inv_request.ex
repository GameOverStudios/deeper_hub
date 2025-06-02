defmodule DeeperHub.Schema.BxInvRequest do
  @moduledoc """
  Schema para representação de bx_inv_requests no sistema

  Este schema armazena as informações de um bx_inv_request.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_inv_requests" do
    field :name, :string  # varchar(255)
    field :email, :string  # varchar(128)
    field :text, :string  # text
    field :nip, :integer, default: 0  # int(11) unsigned
    field :date, :integer, default: 0  # int(11)
    field :status, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_inv_request no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    email: String.t() | nil,
    text: String.t() | nil,
    nip: integer() | nil,
    date: integer() | nil,
    status: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_inv_request.

  ## Parâmetros 
    - `bx_inv_request`: Struct do bx_inv_request (pode ser %BxInvRequest{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_inv_request \ %__MODULE__{}, attrs) do
    bx_inv_request
    |> cast(attrs, [:name, :email, :text, :nip, :date, :status])
    |> validate_required([:name, :email, :text])
    |> validate_email()
  end

  @doc """
  Changeset para atualização de um bx_inv_request existente.

  ## Parâmetros 
    - `bx_inv_request`: Struct do bx_inv_request (%BxInvRequest{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_inv_request \ %__MODULE__{}, attrs) do
    bx_inv_request
    |> cast(attrs, [:name, :email, :text, :nip, :date, :status])
    |> validate_email()
  end
end
