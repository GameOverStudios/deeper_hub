defmodule DeeperHub.Schema.BxCreditsHistory do
  @moduledoc """
  Schema para representação de bx_credits_historys no sistema

  Este schema armazena as informações de um bx_credits_history.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_credits_history" do
    field :first_pid, :integer, default: 0  # int(11)
    field :second_pid, :integer, default: 0  # int(11)
    field :amount, :float, default: 0  # float
    field :type, :string, default: ""  # varchar(16)
    field :direction, Ecto.Enum, values: [:in, :out], default: "in"  # enum('in','out')
    field :order, :string, default: ""  # varchar(32)
    field :data, :string, default: "''"  # text
    field :info, :string, default: ""  # varchar(255)
    field :date, :integer, default: 0  # int(11)
    field :cleared, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_credits_history no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    first_pid: integer() | nil,
    second_pid: integer() | nil,
    amount: float() | nil,
    type: String.t() | nil,
    direction: :in | :out | nil,
    order: String.t() | nil,
    data: String.t() | nil,
    info: String.t() | nil,
    date: integer() | nil,
    cleared: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_credits_history.

  ## Parâmetros 
    - `bx_credits_history`: Struct do bx_credits_history (pode ser %BxCreditsHistory{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_credits_history \ %__MODULE__{}, attrs) do
    bx_credits_history
    |> cast(attrs, [:first_pid, :second_pid, :amount, :type, :direction, :order, :data, :info, :date, :cleared])
    |> validate_required([:type, :order, :info])
  end

  @doc """
  Changeset para atualização de um bx_credits_history existente.

  ## Parâmetros 
    - `bx_credits_history`: Struct do bx_credits_history (%BxCreditsHistory{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_credits_history \ %__MODULE__{}, attrs) do
    bx_credits_history
    |> cast(attrs, [:first_pid, :second_pid, :amount, :type, :direction, :order, :data, :info, :date, :cleared])
  end
end
