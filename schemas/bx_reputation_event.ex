defmodule DeeperHub.Schema.BxReputationEvent do
  @moduledoc """
  Schema para representação de bx_reputation_events no sistema

  Este schema armazena as informações de um bx_reputation_event.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_reputation_events" do
    field :owner_id, :integer, default: 0  # int(11)
    field :type, :string, default: ""  # varchar(64)
    field :action, :string, default: ""  # varchar(64)
    field :object_id, :integer, default: 0  # int(11)
    field :object_owner_id, :integer, default: 0  # int(11)
    field :points, :integer, default: 0  # int(11)
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_reputation_event no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    owner_id: integer() | nil,
    type: String.t() | nil,
    action: String.t() | nil,
    object_id: integer() | nil,
    object_owner_id: integer() | nil,
    points: integer() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_reputation_event.

  ## Parâmetros 
    - `bx_reputation_event`: Struct do bx_reputation_event (pode ser %BxReputationEvent{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_reputation_event \ %__MODULE__{}, attrs) do
    bx_reputation_event
    |> cast(attrs, [:owner_id, :type, :action, :object_id, :object_owner_id, :points, :date])
    |> validate_required([:type, :action])
  end

  @doc """
  Changeset para atualização de um bx_reputation_event existente.

  ## Parâmetros 
    - `bx_reputation_event`: Struct do bx_reputation_event (%BxReputationEvent{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_reputation_event \ %__MODULE__{}, attrs) do
    bx_reputation_event
    |> cast(attrs, [:owner_id, :type, :action, :object_id, :object_owner_id, :points, :date])
  end
end
