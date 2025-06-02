defmodule DeeperHub.Schema.SysFormFieldsId do
  @moduledoc """
  Schema para representação de sys_form_fields_ids no sistema

  Este schema armazena as informações de um sys_form_fields_id.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_form_fields_ids" do
    field :object_form, :string, default: ""  # varchar(64)
    field :module, :string  # varchar(32)
    field :field_name, :string, default: ""  # varchar(255)
    field :content_id, :integer, default: 0  # int(11)
    field :author_id, :integer, default: 0  # int(10)
    field :nested_content_id, :integer, default: 0  # int(10)
    field :rate, :float, default: 0  # float
    field :votes, :integer, default: 0  # int(11)
    field :rrate, :float, default: 0  # float
    field :rvotes, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_form_fields_id no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_form: String.t() | nil,
    module: String.t() | nil,
    field_name: String.t() | nil,
    content_id: integer() | nil,
    author_id: integer() | nil,
    nested_content_id: integer() | nil,
    rate: float() | nil,
    votes: integer() | nil,
    rrate: float() | nil,
    rvotes: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_form_fields_id.

  ## Parâmetros 
    - `sys_form_fields_id`: Struct do sys_form_fields_id (pode ser %SysFormFieldsId{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_form_fields_id \ %__MODULE__{}, attrs) do
    sys_form_fields_id
    |> cast(attrs, [:object_form, :module, :field_name, :content_id, :author_id, :nested_content_id, :rate, :votes, :rrate, :rvotes])
    |> validate_required([:object_form, :module, :field_name])
  end

  @doc """
  Changeset para atualização de um sys_form_fields_id existente.

  ## Parâmetros 
    - `sys_form_fields_id`: Struct do sys_form_fields_id (%SysFormFieldsId{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_form_fields_id \ %__MODULE__{}, attrs) do
    sys_form_fields_id
    |> cast(attrs, [:object_form, :module, :field_name, :content_id, :author_id, :nested_content_id, :rate, :votes, :rrate, :rvotes])
  end
end
