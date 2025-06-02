defmodule DeeperHub.Schema.BxMassmailerUnsubscribe do
  @moduledoc """
  Schema para representação de bx_massmailer_unsubscribes no sistema

  Este schema armazena as informações de um bx_massmailer_unsubscribe.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_massmailer_unsubscribe" do
    field :account_id, :integer  # int(11)
    field :campaign_id, :integer  # int(11)
    field :unsubscribed, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_massmailer_unsubscribe no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    account_id: integer() | nil,
    campaign_id: integer() | nil,
    unsubscribed: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_massmailer_unsubscribe.

  ## Parâmetros 
    - `bx_massmailer_unsubscribe`: Struct do bx_massmailer_unsubscribe (pode ser %BxMassmailerUnsubscribe{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_massmailer_unsubscribe \ %__MODULE__{}, attrs) do
    bx_massmailer_unsubscribe
    |> cast(attrs, [:account_id, :campaign_id, :unsubscribed])
  end

  @doc """
  Changeset para atualização de um bx_massmailer_unsubscribe existente.

  ## Parâmetros 
    - `bx_massmailer_unsubscribe`: Struct do bx_massmailer_unsubscribe (%BxMassmailerUnsubscribe{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_massmailer_unsubscribe \ %__MODULE__{}, attrs) do
    bx_massmailer_unsubscribe
    |> cast(attrs, [:account_id, :campaign_id, :unsubscribed])
  end
end
