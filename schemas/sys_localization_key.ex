defmodule DeeperHub.Schema.SysLocalizationKey do
  @moduledoc """
  Schema para representação de sys_localization_keys no sistema

  Este schema armazena as informações de um sys_localization_key.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_localization_keys" do
    field :ID, :integer  # int(10) unsigned
    field :IDCategory, :integer, default: 0  # int(6) unsigned
    field :Key, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_localization_key no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ID: integer() | nil,
    IDCategory: integer() | nil,
    Key: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_localization_key.

  ## Parâmetros 
    - `sys_localization_key`: Struct do sys_localization_key (pode ser %SysLocalizationKey{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_localization_key \ %__MODULE__{}, attrs) do
    sys_localization_key
    |> cast(attrs, [:ID, :IDCategory, :Key])
    |> validate_required([:ID, :Key])
    |> unique_constraint(:Key)
  end

  @doc """
  Changeset para atualização de um sys_localization_key existente.

  ## Parâmetros 
    - `sys_localization_key`: Struct do sys_localization_key (%SysLocalizationKey{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_localization_key \ %__MODULE__{}, attrs) do
    sys_localization_key
    |> cast(attrs, [:ID, :IDCategory, :Key])
    |> unique_constraint(:Key)
  end
end
