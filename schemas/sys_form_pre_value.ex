defmodule DeeperHub.Schema.SysFormPreValue do
  @moduledoc """
  Schema para representação de sys_form_pre_values no sistema

  Este schema armazena as informações de um sys_form_pre_value.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_form_pre_values" do
    field :Key, :string, default: ""  # varchar(255)
    field :Value, :string, default: ""  # varchar(255)
    field :Order, :integer, default: 0  # int(10) unsigned
    field :LKey, :string, default: ""  # varchar(255)
    field :LKey2, :string, default: ""  # varchar(255)
    field :Data, :string, default: "''"  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_form_pre_value no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    Key: String.t() | nil,
    Value: String.t() | nil,
    Order: integer() | nil,
    LKey: String.t() | nil,
    LKey2: String.t() | nil,
    Data: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_form_pre_value.

  ## Parâmetros 
    - `sys_form_pre_value`: Struct do sys_form_pre_value (pode ser %SysFormPreValue{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_form_pre_value \ %__MODULE__{}, attrs) do
    sys_form_pre_value
    |> cast(attrs, [:Key, :Value, :Order, :LKey, :LKey2, :Data])
    |> validate_required([:Key, :Value, :LKey, :LKey2])
  end

  @doc """
  Changeset para atualização de um sys_form_pre_value existente.

  ## Parâmetros 
    - `sys_form_pre_value`: Struct do sys_form_pre_value (%SysFormPreValue{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_form_pre_value \ %__MODULE__{}, attrs) do
    sys_form_pre_value
    |> cast(attrs, [:Key, :Value, :Order, :LKey, :LKey2, :Data])
  end
end
