defmodule DeeperHub.Schema.BxCreditsWithdrawal do
  @moduledoc """
  Schema para representação de bx_credits_withdrawals no sistema

  Este schema armazena as informações de um bx_credits_withdrawal.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_credits_withdrawals" do
    field :performer_id, :integer, default: 0  # int(11) unsigned
    field :profile_id, :integer, default: 0  # int(11) unsigned
    field :amount, :float, default: 0  # float
    field :rate, :float, default: 0  # float
    field :message, :string, default: "''"  # text
    field :order, :string, default: ""  # varchar(32)
    field :added, :integer, default: 0  # int(11) unsigned
    field :confirmed, :integer, default: 0  # int(11) unsigned
    field :status, Ecto.Enum, values: [:requested, :canceled, :confirmed], default: "requested"  # enum('requested','canceled','confirmed')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_credits_withdrawal no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    performer_id: integer() | nil,
    profile_id: integer() | nil,
    amount: float() | nil,
    rate: float() | nil,
    message: String.t() | nil,
    order: String.t() | nil,
    added: integer() | nil,
    confirmed: integer() | nil,
    status: :requested | :canceled | :confirmed | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_credits_withdrawal.

  ## Parâmetros 
    - `bx_credits_withdrawal`: Struct do bx_credits_withdrawal (pode ser %BxCreditsWithdrawal{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_credits_withdrawal \ %__MODULE__{}, attrs) do
    bx_credits_withdrawal
    |> cast(attrs, [:performer_id, :profile_id, :amount, :rate, :message, :order, :added, :confirmed, :status])
    |> validate_required([:order])
  end

  @doc """
  Changeset para atualização de um bx_credits_withdrawal existente.

  ## Parâmetros 
    - `bx_credits_withdrawal`: Struct do bx_credits_withdrawal (%BxCreditsWithdrawal{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_credits_withdrawal \ %__MODULE__{}, attrs) do
    bx_credits_withdrawal
    |> cast(attrs, [:performer_id, :profile_id, :amount, :rate, :message, :order, :added, :confirmed, :status])
  end
end
