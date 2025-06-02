defmodule DeeperHub.Schema.BxReputationHandler do
  @moduledoc """
  Schema para representação de bx_reputation_handlers no sistema

  Este schema armazena as informações de um bx_reputation_handler.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_reputation_handlers" do
    field :group, :string, default: ""  # varchar(64)
    field :type, Ecto.Enum, values: [:insert, :update, :delete], default: "insert"  # enum('insert','update','delete')
    field :alert_unit, :string, default: ""  # varchar(64)
    field :alert_action, :string, default: ""  # varchar(64)
    field :points_active, :integer, default: 0  # int(11)
    field :points_passive, :integer, default: 0  # int(11)
    field :active, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_reputation_handler no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    group: String.t() | nil,
    type: :insert | :update | :delete | nil,
    alert_unit: String.t() | nil,
    alert_action: String.t() | nil,
    points_active: integer() | nil,
    points_passive: integer() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_reputation_handler.

  ## Parâmetros 
    - `bx_reputation_handler`: Struct do bx_reputation_handler (pode ser %BxReputationHandler{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_reputation_handler \ %__MODULE__{}, attrs) do
    bx_reputation_handler
    |> cast(attrs, [:group, :type, :alert_unit, :alert_action, :points_active, :points_passive, :active])
    |> validate_required([:group, :alert_unit, :alert_action])
  end

  @doc """
  Changeset para atualização de um bx_reputation_handler existente.

  ## Parâmetros 
    - `bx_reputation_handler`: Struct do bx_reputation_handler (%BxReputationHandler{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_reputation_handler \ %__MODULE__{}, attrs) do
    bx_reputation_handler
    |> cast(attrs, [:group, :type, :alert_unit, :alert_action, :points_active, :points_passive, :active])
  end
end
