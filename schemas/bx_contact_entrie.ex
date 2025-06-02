defmodule DeeperHub.Schema.BxContactEntrie do
  @moduledoc """
  Schema para representação de bx_contact_entries no sistema

  Este schema armazena as informações de um bx_contact_entrie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_contact_entries" do
    field :name, :string  # varchar(255)
    field :email, :string  # varchar(128)
    field :subject, :string  # varchar(128)
    field :body, :string  # text
    field :uri, :string  # varchar(255)
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_contact_entrie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    email: String.t() | nil,
    subject: String.t() | nil,
    body: String.t() | nil,
    uri: String.t() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_contact_entrie.

  ## Parâmetros 
    - `bx_contact_entrie`: Struct do bx_contact_entrie (pode ser %BxContactEntrie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_contact_entrie \ %__MODULE__{}, attrs) do
    bx_contact_entrie
    |> cast(attrs, [:name, :email, :subject, :body, :uri, :date])
    |> validate_required([:name, :email, :subject, :body, :uri])
    |> validate_email()
  end

  @doc """
  Changeset para atualização de um bx_contact_entrie existente.

  ## Parâmetros 
    - `bx_contact_entrie`: Struct do bx_contact_entrie (%BxContactEntrie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_contact_entrie \ %__MODULE__{}, attrs) do
    bx_contact_entrie
    |> cast(attrs, [:name, :email, :subject, :body, :uri, :date])
    |> validate_email()
  end
end
