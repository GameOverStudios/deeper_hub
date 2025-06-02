defmodule DeeperHub.Schema.SysMenuTemplate do
  @moduledoc """
  Schema para representação de sys_menu_templates no sistema

  Este schema armazena as informações de um sys_menu_template.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_menu_templates" do
    field :template, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :visible, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_menu_template no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    template: String.t() | nil,
    title: String.t() | nil,
    visible: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_menu_template.

  ## Parâmetros 
    - `sys_menu_template`: Struct do sys_menu_template (pode ser %SysMenuTemplate{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_menu_template \ %__MODULE__{}, attrs) do
    sys_menu_template
    |> cast(attrs, [:template, :title, :visible])
    |> validate_required([:template, :title])
  end

  @doc """
  Changeset para atualização de um sys_menu_template existente.

  ## Parâmetros 
    - `sys_menu_template`: Struct do sys_menu_template (%SysMenuTemplate{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_menu_template \ %__MODULE__{}, attrs) do
    sys_menu_template
    |> cast(attrs, [:template, :title, :visible])
  end
end
