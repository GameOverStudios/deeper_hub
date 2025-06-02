defmodule DeeperHub.Schema.SysObjectsMetatag do
  @moduledoc """
  Schema para representação de sys_objects_metatags no sistema

  Este schema armazena as informações de um sys_objects_metatag.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_metatags" do
    field :object, :string  # varchar(64)
    field :module, :string  # varchar(32)
    field :table_keywords, :string  # varchar(255)
    field :table_locations, :string  # varchar(255)
    field :table_mentions, :string  # varchar(255)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_metatag no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    module: String.t() | nil,
    table_keywords: String.t() | nil,
    table_locations: String.t() | nil,
    table_mentions: String.t() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_metatag.

  ## Parâmetros 
    - `sys_objects_metatag`: Struct do sys_objects_metatag (pode ser %SysObjectsMetatag{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_metatag \ %__MODULE__{}, attrs) do
    sys_objects_metatag
    |> cast(attrs, [:object, :module, :table_keywords, :table_locations, :table_mentions, :override_class_name, :override_class_file])
    |> validate_required([:object, :module, :table_keywords, :table_locations, :table_mentions, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_metatag existente.

  ## Parâmetros 
    - `sys_objects_metatag`: Struct do sys_objects_metatag (%SysObjectsMetatag{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_metatag \ %__MODULE__{}, attrs) do
    sys_objects_metatag
    |> cast(attrs, [:object, :module, :table_keywords, :table_locations, :table_mentions, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end
end
