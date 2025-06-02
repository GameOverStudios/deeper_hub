defmodule DeeperHub.Schema.SysAudit do
  @moduledoc """
  Schema para representação de sys_audits no sistema

  Este schema armazena as informações de um sys_audit.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_audit" do
    field :added, :integer  # int(11)
    field :profile_id, :integer  # int(10)
    field :profile_title, :string  # varchar(255)
    field :content_id, :integer  # int(10)
    field :content_title, :string  # varchar(255)
    field :content_module, :string, default: ""  # varchar(32)
    field :content_info_object, :string, default: ""  # varchar(32)
    field :context_profile_id, :integer  # int(10)
    field :context_profile_title, :string  # varchar(255)
    field :action_lang_key, :string  # varchar(255)
    field :action_lang_key_params, :string  # text
    field :extras, :string  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_audit no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    added: integer() | nil,
    profile_id: integer() | nil,
    profile_title: String.t() | nil,
    content_id: integer() | nil,
    content_title: String.t() | nil,
    content_module: String.t() | nil,
    content_info_object: String.t() | nil,
    context_profile_id: integer() | nil,
    context_profile_title: String.t() | nil,
    action_lang_key: String.t() | nil,
    action_lang_key_params: String.t() | nil,
    extras: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_audit.

  ## Parâmetros 
    - `sys_audit`: Struct do sys_audit (pode ser %SysAudit{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_audit \ %__MODULE__{}, attrs) do
    sys_audit
    |> cast(attrs, [:added, :profile_id, :profile_title, :content_id, :content_title, :content_module, :content_info_object, :context_profile_id, :context_profile_title, :action_lang_key, :action_lang_key_params, :extras])
    |> validate_required([:added, :profile_id, :profile_title, :content_id, :content_title, :content_module, :content_info_object, :context_profile_id, :context_profile_title, :action_lang_key, :action_lang_key_params, :extras])
  end

  @doc """
  Changeset para atualização de um sys_audit existente.

  ## Parâmetros 
    - `sys_audit`: Struct do sys_audit (%SysAudit{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_audit \ %__MODULE__{}, attrs) do
    sys_audit
    |> cast(attrs, [:added, :profile_id, :profile_title, :content_id, :content_title, :content_module, :content_info_object, :context_profile_id, :context_profile_title, :action_lang_key, :action_lang_key_params, :extras])
  end
end
