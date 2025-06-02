defmodule DeeperHub.Schema.SysPagesWikiBlock do
  @moduledoc """
  Schema para representação de sys_pages_wiki_blocks no sistema

  Este schema armazena as informações de um sys_pages_wiki_block.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_pages_wiki_blocks" do
    field :block_id, :integer  # int(11)
    field :revision, :integer  # int(11)
    field :language, :string  # varchar(5)
    field :main_lang, :integer, default: 0  # tinyint(4)
    field :profile_id, :integer  # int(10) unsigned
    field :content, :string  # mediumtext
    field :unsafe, :integer, default: 0  # tinyint(4)
    field :notes, :string  # varchar(255)
    field :added, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_pages_wiki_block no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    block_id: integer() | nil,
    revision: integer() | nil,
    language: String.t() | nil,
    main_lang: integer() | nil,
    profile_id: integer() | nil,
    content: String.t() | nil,
    unsafe: integer() | nil,
    notes: String.t() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_pages_wiki_block.

  ## Parâmetros 
    - `sys_pages_wiki_block`: Struct do sys_pages_wiki_block (pode ser %SysPagesWikiBlock{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_pages_wiki_block \ %__MODULE__{}, attrs) do
    sys_pages_wiki_block
    |> cast(attrs, [:block_id, :revision, :language, :main_lang, :profile_id, :content, :unsafe, :notes, :added])
    |> validate_required([:block_id, :revision, :language, :profile_id, :content, :notes, :added])
  end

  @doc """
  Changeset para atualização de um sys_pages_wiki_block existente.

  ## Parâmetros 
    - `sys_pages_wiki_block`: Struct do sys_pages_wiki_block (%SysPagesWikiBlock{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_pages_wiki_block \ %__MODULE__{}, attrs) do
    sys_pages_wiki_block
    |> cast(attrs, [:block_id, :revision, :language, :main_lang, :profile_id, :content, :unsafe, :notes, :added])
  end
end
