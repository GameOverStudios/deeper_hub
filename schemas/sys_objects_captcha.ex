defmodule DeeperHub.Schema.SysObjectsCaptcha do
  @moduledoc """
  Schema para representação de sys_objects_captchas no sistema

  Este schema armazena as informações de um sys_objects_captcha.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_captcha" do
    field :object, :string  # varchar(64)
    field :title, :string  # varchar(255)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_captcha no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    title: String.t() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_captcha.

  ## Parâmetros 
    - `sys_objects_captcha`: Struct do sys_objects_captcha (pode ser %SysObjectsCaptcha{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_captcha \ %__MODULE__{}, attrs) do
    sys_objects_captcha
    |> cast(attrs, [:object, :title, :override_class_name, :override_class_file])
    |> validate_required([:object, :title, :override_class_name, :override_class_file])
  end

  @doc """
  Changeset para atualização de um sys_objects_captcha existente.

  ## Parâmetros 
    - `sys_objects_captcha`: Struct do sys_objects_captcha (%SysObjectsCaptcha{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_captcha \ %__MODULE__{}, attrs) do
    sys_objects_captcha
    |> cast(attrs, [:object, :title, :override_class_name, :override_class_file])
  end
end
