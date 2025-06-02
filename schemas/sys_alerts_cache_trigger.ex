defmodule DeeperHub.Schema.SysAlertsCacheTrigger do
  @moduledoc """
  Schema para representação de sys_alerts_cache_triggers no sistema

  Este schema armazena as informações de um sys_alerts_cache_trigger.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_alerts_cache_triggers" do
    field :unit, :string, default: ""  # varchar(128)
    field :action, :string, default: ""  # varchar(32)
    field :cache_key, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_alerts_cache_trigger no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    unit: String.t() | nil,
    action: String.t() | nil,
    cache_key: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_alerts_cache_trigger.

  ## Parâmetros 
    - `sys_alerts_cache_trigger`: Struct do sys_alerts_cache_trigger (pode ser %SysAlertsCacheTrigger{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_alerts_cache_trigger \ %__MODULE__{}, attrs) do
    sys_alerts_cache_trigger
    |> cast(attrs, [:unit, :action, :cache_key])
    |> validate_required([:unit, :action, :cache_key])
  end

  @doc """
  Changeset para atualização de um sys_alerts_cache_trigger existente.

  ## Parâmetros 
    - `sys_alerts_cache_trigger`: Struct do sys_alerts_cache_trigger (%SysAlertsCacheTrigger{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_alerts_cache_trigger \ %__MODULE__{}, attrs) do
    sys_alerts_cache_trigger
    |> cast(attrs, [:unit, :action, :cache_key])
  end
end
