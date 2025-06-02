defmodule DeeperHub.Schema.SysLocalizationString do
  @moduledoc """
  Schema para representação de sys_localization_strings no sistema

  Este schema armazena as informações de um sys_localization_string.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_localization_strings" do
    field :IDKey, :integer, default: 0  # int(10) unsigned
    field :IDLanguage, :integer, default: 0  # int(10) unsigned
    field :String, :string  # mediumtext

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_localization_string no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    IDKey: integer() | nil,
    IDLanguage: integer() | nil,
    String: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_localization_string.

  ## Parâmetros 
    - `sys_localization_string`: Struct do sys_localization_string (pode ser %SysLocalizationString{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_localization_string \ %__MODULE__{}, attrs) do
    sys_localization_string
    |> cast(attrs, [:IDKey, :IDLanguage, :String])
    |> validate_required([:String])
  end

  @doc """
  Changeset para atualização de um sys_localization_string existente.

  ## Parâmetros 
    - `sys_localization_string`: Struct do sys_localization_string (%SysLocalizationString{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_localization_string \ %__MODULE__{}, attrs) do
    sys_localization_string
    |> cast(attrs, [:IDKey, :IDLanguage, :String])
  end
end
