defmodule DeeperHub.Schema.SysObjectsWiki do
  @moduledoc """
  Schema para representação de sys_objects_wikis no sistema

  Este schema armazena as informações de um sys_objects_wiki.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_wiki" do
    field :object, :string  # varchar(64)
    field :uri, :string  # varchar(32)
    field :title, :string  # varchar(255)
    field :module, :string  # varchar(32)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_wiki no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    uri: String.t() | nil,
    title: String.t() | nil,
    module: String.t() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_wiki.

  ## Parâmetros 
    - `sys_objects_wiki`: Struct do sys_objects_wiki (pode ser %SysObjectsWiki{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_wiki \ %__MODULE__{}, attrs) do
    sys_objects_wiki
    |> cast(attrs, [:object, :uri, :title, :module, :override_class_name, :override_class_file])
    |> validate_required([:object, :uri, :title, :module, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
    |> unique_constraint(:uri)
  end

  @doc """
  Changeset para atualização de um sys_objects_wiki existente.

  ## Parâmetros 
    - `sys_objects_wiki`: Struct do sys_objects_wiki (%SysObjectsWiki{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_wiki \ %__MODULE__{}, attrs) do
    sys_objects_wiki
    |> cast(attrs, [:object, :uri, :title, :module, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
    |> unique_constraint(:uri)
  end
end
