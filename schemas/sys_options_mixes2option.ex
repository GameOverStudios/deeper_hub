defmodule DeeperHub.Schema.SysOptionsMixes2option do
  @moduledoc """
  Schema para representação de sys_options_mixes2options no sistema

  Este schema armazena as informações de um sys_options_mixes2option.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_options_mixes2options" do
    field :option, :string, default: ""  # varchar(64)
    field :mix_id, :integer, default: 0  # int(11) unsigned
    field :value, :string  # mediumtext

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_options_mixes2option no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    option: String.t() | nil,
    mix_id: integer() | nil,
    value: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_options_mixes2option.

  ## Parâmetros 
    - `sys_options_mixes2option`: Struct do sys_options_mixes2option (pode ser %SysOptionsMixes2option{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_options_mixes2option \ %__MODULE__{}, attrs) do
    sys_options_mixes2option
    |> cast(attrs, [:option, :mix_id, :value])
    |> validate_required([:option, :value])
  end

  @doc """
  Changeset para atualização de um sys_options_mixes2option existente.

  ## Parâmetros 
    - `sys_options_mixes2option`: Struct do sys_options_mixes2option (%SysOptionsMixes2option{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_options_mixes2option \ %__MODULE__{}, attrs) do
    sys_options_mixes2option
    |> cast(attrs, [:option, :mix_id, :value])
  end
end
