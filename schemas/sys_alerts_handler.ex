defmodule DeeperHub.Schema.SysAlertsHandler do
  @moduledoc """
  Schema para representação de sys_alerts_handlers no sistema

  Este schema armazena as informações de um sys_alerts_handler.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_alerts_handlers" do
    field :name, :string, default: ""  # varchar(128)
    field :class, :string, default: ""  # varchar(128)
    field :file, :string, default: ""  # varchar(255)
    field :service_call, :string, default: "''"  # text
    field :active, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_alerts_handler no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    class: String.t() | nil,
    file: String.t() | nil,
    service_call: String.t() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_alerts_handler.

  ## Parâmetros 
    - `sys_alerts_handler`: Struct do sys_alerts_handler (pode ser %SysAlertsHandler{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_alerts_handler \ %__MODULE__{}, attrs) do
    sys_alerts_handler
    |> cast(attrs, [:name, :class, :file, :service_call, :active])
    |> validate_required([:name, :class, :file])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_alerts_handler existente.

  ## Parâmetros 
    - `sys_alerts_handler`: Struct do sys_alerts_handler (%SysAlertsHandler{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_alerts_handler \ %__MODULE__{}, attrs) do
    sys_alerts_handler
    |> cast(attrs, [:name, :class, :file, :service_call, :active])
    |> unique_constraint(:name)
  end
end
