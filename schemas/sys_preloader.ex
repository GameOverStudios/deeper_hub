defmodule DeeperHub.Schema.SysPreloader do
  @moduledoc """
  Schema para representação de sys_preloaders no sistema

  Este schema armazena as informações de um sys_preloader.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_preloader" do
    field :module, :string  # varchar(32)
    field :type, :string  # varchar(16)
    field :content, :string  # varchar(255)
    field :active, :integer, default: 1  # tinyint(4)
    field :order, :integer, default: 0  # int(11) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_preloader no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    module: String.t() | nil,
    type: String.t() | nil,
    content: String.t() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_preloader.

  ## Parâmetros 
    - `sys_preloader`: Struct do sys_preloader (pode ser %SysPreloader{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_preloader \ %__MODULE__{}, attrs) do
    sys_preloader
    |> cast(attrs, [:module, :type, :content, :active, :order])
    |> validate_required([:module, :type, :content])
  end

  @doc """
  Changeset para atualização de um sys_preloader existente.

  ## Parâmetros 
    - `sys_preloader`: Struct do sys_preloader (%SysPreloader{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_preloader \ %__MODULE__{}, attrs) do
    sys_preloader
    |> cast(attrs, [:module, :type, :content, :active, :order])
  end
end
