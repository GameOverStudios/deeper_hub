defmodule DeeperHub.Schema.SysAlert do
  @moduledoc """
  Schema para representação de sys_alerts no sistema

  Este schema armazena as informações de um sys_alert.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_alerts" do
    field :unit, :string, default: ""  # varchar(128)
    field :action, :string, default: "none"  # varchar(32)
    field :handler_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_alert no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    unit: String.t() | nil,
    action: String.t() | nil,
    handler_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_alert.

  ## Parâmetros 
    - `sys_alert`: Struct do sys_alert (pode ser %SysAlert{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_alert \ %__MODULE__{}, attrs) do
    sys_alert
    |> cast(attrs, [:unit, :action, :handler_id])
    |> validate_required([:unit])
  end

  @doc """
  Changeset para atualização de um sys_alert existente.

  ## Parâmetros 
    - `sys_alert`: Struct do sys_alert (%SysAlert{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_alert \ %__MODULE__{}, attrs) do
    sys_alert
    |> cast(attrs, [:unit, :action, :handler_id])
  end
end
