defmodule DeeperHub.Schema.SysLocalizationCategorie do
  @moduledoc """
  Schema para representação de sys_localization_categories no sistema

  Este schema armazena as informações de um sys_localization_categorie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_localization_categories" do
    field :ID, :integer  # int(6) unsigned
    field :Name, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_localization_categorie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ID: integer() | nil,
    Name: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_localization_categorie.

  ## Parâmetros 
    - `sys_localization_categorie`: Struct do sys_localization_categorie (pode ser %SysLocalizationCategorie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_localization_categorie \ %__MODULE__{}, attrs) do
    sys_localization_categorie
    |> cast(attrs, [:ID, :Name])
    |> validate_required([:ID, :Name])
    |> unique_constraint(:Name)
  end

  @doc """
  Changeset para atualização de um sys_localization_categorie existente.

  ## Parâmetros 
    - `sys_localization_categorie`: Struct do sys_localization_categorie (%SysLocalizationCategorie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_localization_categorie \ %__MODULE__{}, attrs) do
    sys_localization_categorie
    |> cast(attrs, [:ID, :Name])
    |> unique_constraint(:Name)
  end
end
