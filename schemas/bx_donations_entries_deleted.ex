defmodule DeeperHub.Schema.BxDonationsEntriesDeleted do
  @moduledoc """
  Schema para representação de bx_donations_entries_deleteds no sistema

  Este schema armazena as informações de um bx_donations_entries_deleted.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_donations_entries_deleted" do
    field :profile_id, :integer, default: 0  # int(11) unsigned
    field :type_id, :integer, default: 0  # int(11)
    field :period, :integer, default: 0  # int(11) unsigned
    field :period_unit, :string, default: ""  # varchar(32)
    field :amount, :float, default: 0  # float unsigned
    field :order, :string, default: ""  # varchar(32)
    field :license, :string, default: ""  # varchar(32)
    field :added, :integer, default: 0  # int(11) unsigned
    field :reason, :string, default: ""  # varchar(16)
    field :deleted, :integer, default: 0  # int(11) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_donations_entries_deleted no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    type_id: integer() | nil,
    period: integer() | nil,
    period_unit: String.t() | nil,
    amount: float() | nil,
    order: String.t() | nil,
    license: String.t() | nil,
    added: integer() | nil,
    reason: String.t() | nil,
    deleted: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_donations_entries_deleted.

  ## Parâmetros 
    - `bx_donations_entries_deleted`: Struct do bx_donations_entries_deleted (pode ser %BxDonationsEntriesDeleted{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_donations_entries_deleted \ %__MODULE__{}, attrs) do
    bx_donations_entries_deleted
    |> cast(attrs, [:profile_id, :type_id, :period, :period_unit, :amount, :order, :license, :added, :reason, :deleted])
    |> validate_required([:period_unit, :order, :license, :reason])
  end

  @doc """
  Changeset para atualização de um bx_donations_entries_deleted existente.

  ## Parâmetros 
    - `bx_donations_entries_deleted`: Struct do bx_donations_entries_deleted (%BxDonationsEntriesDeleted{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_donations_entries_deleted \ %__MODULE__{}, attrs) do
    bx_donations_entries_deleted
    |> cast(attrs, [:profile_id, :type_id, :period, :period_unit, :amount, :order, :license, :added, :reason, :deleted])
  end
end
