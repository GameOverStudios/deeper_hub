defmodule DeeperHub.Schema.BxMassmailerLetter do
  @moduledoc """
  Schema para representação de bx_massmailer_letters no sistema

  Este schema armazena as informações de um bx_massmailer_letter.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_massmailer_letters" do
    field :campaign_id, :integer  # int(11)
    field :email, :string  # varchar(255)
    field :date_sent, :integer, default: 0  # int(11)
    field :date_seen, :integer, default: 0  # int(11)
    field :date_click, :integer, default: 0  # int(11)
    field :hash, :string  # varchar(35)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_massmailer_letter no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    campaign_id: integer() | nil,
    email: String.t() | nil,
    date_sent: integer() | nil,
    date_seen: integer() | nil,
    date_click: integer() | nil,
    hash: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_massmailer_letter.

  ## Parâmetros 
    - `bx_massmailer_letter`: Struct do bx_massmailer_letter (pode ser %BxMassmailerLetter{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_massmailer_letter \ %__MODULE__{}, attrs) do
    bx_massmailer_letter
    |> cast(attrs, [:campaign_id, :email, :date_sent, :date_seen, :date_click, :hash])
    |> validate_required([:campaign_id, :email, :hash])
    |> validate_email()
  end

  @doc """
  Changeset para atualização de um bx_massmailer_letter existente.

  ## Parâmetros 
    - `bx_massmailer_letter`: Struct do bx_massmailer_letter (%BxMassmailerLetter{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_massmailer_letter \ %__MODULE__{}, attrs) do
    bx_massmailer_letter
    |> cast(attrs, [:campaign_id, :email, :date_sent, :date_seen, :date_click, :hash])
    |> validate_email()
  end
end
