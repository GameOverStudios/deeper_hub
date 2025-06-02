defmodule DeeperHub.Schema.SysLocalizationLanguage do
  @moduledoc """
  Schema para representação de sys_localization_languages no sistema

  Este schema armazena as informações de um sys_localization_language.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_localization_languages" do
    field :ID, :integer  # int(10) unsigned
    field :Name, :string, default: ""  # varchar(5)
    field :Flag, :string, default: ""  # varchar(2)
    field :Title, :string, default: ""  # varchar(255)
    field :Direction, Ecto.Enum, values: [:LTR, :RTL], default: "LTR"  # enum('LTR','RTL')
    field :LanguageCountry, :string  # varchar(8)
    field :Enabled, :boolean, default: false  # tinyint(1) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_localization_language no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ID: integer() | nil,
    Name: String.t() | nil,
    Flag: String.t() | nil,
    Title: String.t() | nil,
    Direction: :LTR | :RTL | nil,
    LanguageCountry: String.t() | nil,
    Enabled: boolean() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_localization_language.

  ## Parâmetros 
    - `sys_localization_language`: Struct do sys_localization_language (pode ser %SysLocalizationLanguage{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_localization_language \ %__MODULE__{}, attrs) do
    sys_localization_language
    |> cast(attrs, [:ID, :Name, :Flag, :Title, :Direction, :LanguageCountry, :Enabled])
    |> validate_required([:ID, :Name, :Flag, :Title, :LanguageCountry])
    |> unique_constraint(:Name)
  end

  @doc """
  Changeset para atualização de um sys_localization_language existente.

  ## Parâmetros 
    - `sys_localization_language`: Struct do sys_localization_language (%SysLocalizationLanguage{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_localization_language \ %__MODULE__{}, attrs) do
    sys_localization_language
    |> cast(attrs, [:ID, :Name, :Flag, :Title, :Direction, :LanguageCountry, :Enabled])
    |> unique_constraint(:Name)
  end
end
