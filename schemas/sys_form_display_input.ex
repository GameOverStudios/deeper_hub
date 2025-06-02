defmodule DeeperHub.Schema.SysFormDisplayInput do
  @moduledoc """
  Schema para representação de sys_form_display_inputs no sistema

  Este schema armazena as informações de um sys_form_display_input.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_form_display_inputs" do
    field :display_name, :string  # varchar(64)
    field :input_name, :string  # varchar(32)
    field :visible_for_levels, :integer, default: 2147483647  # int(11)
    field :active, :integer, default: 0  # tinyint(4)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_form_display_input no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    display_name: String.t() | nil,
    input_name: String.t() | nil,
    visible_for_levels: integer() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_form_display_input.

  ## Parâmetros 
    - `sys_form_display_input`: Struct do sys_form_display_input (pode ser %SysFormDisplayInput{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_form_display_input \ %__MODULE__{}, attrs) do
    sys_form_display_input
    |> cast(attrs, [:display_name, :input_name, :visible_for_levels, :active, :order])
    |> validate_required([:display_name, :input_name, :order])
  end

  @doc """
  Changeset para atualização de um sys_form_display_input existente.

  ## Parâmetros 
    - `sys_form_display_input`: Struct do sys_form_display_input (%SysFormDisplayInput{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_form_display_input \ %__MODULE__{}, attrs) do
    sys_form_display_input
    |> cast(attrs, [:display_name, :input_name, :visible_for_levels, :active, :order])
  end
end
