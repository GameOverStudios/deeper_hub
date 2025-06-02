defmodule DeeperHub.Schema.SysFormDisplay do
  @moduledoc """
  Schema para representação de sys_form_displays no sistema

  Este schema armazena as informações de um sys_form_display.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_form_displays" do
    field :display_name, :string  # varchar(64)
    field :module, :string  # varchar(32)
    field :object, :string  # varchar(64)
    field :title, :string  # varchar(255)
    field :view_mode, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_form_display no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    display_name: String.t() | nil,
    module: String.t() | nil,
    object: String.t() | nil,
    title: String.t() | nil,
    view_mode: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_form_display.

  ## Parâmetros 
    - `sys_form_display`: Struct do sys_form_display (pode ser %SysFormDisplay{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_form_display \ %__MODULE__{}, attrs) do
    sys_form_display
    |> cast(attrs, [:display_name, :module, :object, :title, :view_mode])
    |> validate_required([:display_name, :module, :object, :title])
  end

  @doc """
  Changeset para atualização de um sys_form_display existente.

  ## Parâmetros 
    - `sys_form_display`: Struct do sys_form_display (%SysFormDisplay{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_form_display \ %__MODULE__{}, attrs) do
    sys_form_display
    |> cast(attrs, [:display_name, :module, :object, :title, :view_mode])
  end
end
