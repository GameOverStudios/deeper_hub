defmodule DeeperHub.Schema.BxTimelineHandler do
  @moduledoc """
  Schema para representação de bx_timeline_handlers no sistema

  Este schema armazena as informações de um bx_timeline_handler.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_timeline_handlers" do
    field :group, :string, default: ""  # varchar(64)
    field :type, Ecto.Enum, values: [:insert, :update, :delete], default: "insert"  # enum('insert','update','delete')
    field :alert_unit, :string, default: ""  # varchar(64)
    field :alert_action, :string, default: ""  # varchar(64)
    field :content, :string  # text
    field :privacy, :string, default: ""  # varchar(64)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_timeline_handler no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    group: String.t() | nil,
    type: :insert | :update | :delete | nil,
    alert_unit: String.t() | nil,
    alert_action: String.t() | nil,
    content: String.t() | nil,
    privacy: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_timeline_handler.

  ## Parâmetros 
    - `bx_timeline_handler`: Struct do bx_timeline_handler (pode ser %BxTimelineHandler{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_timeline_handler \ %__MODULE__{}, attrs) do
    bx_timeline_handler
    |> cast(attrs, [:group, :type, :alert_unit, :alert_action, :content, :privacy])
    |> validate_required([:group, :alert_unit, :alert_action, :content, :privacy])
  end

  @doc """
  Changeset para atualização de um bx_timeline_handler existente.

  ## Parâmetros 
    - `bx_timeline_handler`: Struct do bx_timeline_handler (%BxTimelineHandler{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_timeline_handler \ %__MODULE__{}, attrs) do
    bx_timeline_handler
    |> cast(attrs, [:group, :type, :alert_unit, :alert_action, :content, :privacy])
  end
end
