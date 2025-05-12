defmodule DeeperHub.Core.ConfigManager.Services.Setting do
  @moduledoc """
  Serviço para gerenciar as configurações armazenadas no banco de dados Mnesia.

  Este serviço oferece operações CRUD para configurações, incluindo validação,
  serialização/deserialização de valores, e interação com o banco de dados.
  """

  alias DeeperHub.Core.ConfigManager.Schema.Setting
  alias DeeperHub.Core.ConfigManager.Schema.SettingTable

  @doc """
  Inicializa as tabelas necessárias para o serviço de configurações.
  """
  def setup do
    Memento.Table.create(SettingTable)
  end

  @doc """
  Cria uma nova configuração.

  ## Parâmetros

    * `attrs` - Um mapa com os atributos da configuração.

  ## Retorno

    * `{:ok, setting}` - Em caso de sucesso.
    * `{:error, reason}` - Se houver erros de validação.
  """
  def create(attrs) do
    with {:ok, setting} <- Setting.new(attrs) do
      Memento.transaction! fn ->
        Memento.Query.write(setting)
      end

      {:ok, setting}
    end
  end

  @doc """
  Obtém uma configuração pela chave e escopo.

  ## Parâmetros

    * `key` - A chave da configuração.
    * `scope` - O escopo da configuração (padrão: "global").

  ## Retorno

    * `{:ok, setting}` - Se a configuração for encontrada.
    * `{:error, :not_found}` - Se a configuração não for encontrada.
  """
  def get_by_key_and_scope(key, scope \\ "global") do
    result = Memento.transaction! fn ->
      Memento.Query.select(SettingTable, {:==, :key, key})
      |> Enum.filter(fn setting ->
        setting.scope == scope && is_nil(setting.deleted_at)
      end)
      |> List.first()
    end

    case result do
      nil -> {:error, :not_found}
      setting ->
        value = Setting.deserialize_value(setting.value, setting.data_type)
        setting = Map.put(setting, :value, value)
        {:ok, setting}
    end
  end

  @doc """
  Atualiza uma configuração existente.

  ## Parâmetros

    * `setting` - A configuração a ser atualizada.
    * `attrs` - Um mapa com os novos atributos.

  ## Retorno

    * `{:ok, updated_setting}` - Em caso de sucesso.
    * `{:error, reason}` - Se houver erros de validação.
  """
  def update(setting, attrs) do
    # Mescla os atributos existentes com os novos
    attrs = Map.merge(Map.from_struct(setting), attrs)
    attrs = Map.put(attrs, :updated_at, DateTime.utc_now() |> DateTime.to_iso8601())

    with {:ok, updated_setting} <- Setting.validate(attrs) do
      Memento.transaction! fn ->
        Memento.Query.write(updated_setting)
      end

      {:ok, updated_setting}
    end
  end

  @doc """
  Exclui logicamente uma configuração (soft-delete).

  ## Parâmetros

    * `setting` - A configuração a ser excluída.
    * `deleted_by` - Identificador de quem está fazendo a exclusão.

  ## Retorno

    * `{:ok, setting}` - Em caso de sucesso.
    * `{:error, reason}` - Se houver erros.
  """
  def delete(setting, deleted_by \\ "system") do
    attrs = %{
      deleted_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      deleted_by: deleted_by,
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    update(setting, attrs)
  end

  @doc """
  Lista todas as configurações para um escopo específico.

  ## Parâmetros

    * `scope` - O escopo das configurações (padrão: "global").

  ## Retorno

    * Lista de configurações.
  """
  def list_by_scope(scope \\ "global") do
    Memento.transaction! fn ->
      Memento.Query.select(SettingTable, {:==, :scope, scope})
      |> Enum.filter(fn setting -> is_nil(setting.deleted_at) end)
      |> Enum.map(fn setting ->
        value = Setting.deserialize_value(setting.value, setting.data_type)
        Map.put(setting, :value, value)
      end)
    end
  end

  @doc """
  Lista todas as configurações que correspondem a um padrão de chave.

  ## Parâmetros

    * `key_pattern` - O padrão da chave (como regex string).
    * `scope` - O escopo das configurações (padrão: "global").

  ## Retorno

    * Lista de configurações.
  """
  def list_by_key_pattern(key_pattern, scope \\ "global") do
    # Compile the regex pattern
    regex = Regex.compile!(key_pattern)

    Memento.transaction! fn ->
      Memento.Query.select(SettingTable, {:==, :scope, scope})
      |> Enum.filter(fn setting ->
        is_nil(setting.deleted_at) && Regex.match?(regex, setting.key)
      end)
      |> Enum.map(fn setting ->
        value = Setting.deserialize_value(setting.value, setting.data_type)
        Map.put(setting, :value, value)
      end)
    end
  end

  @doc """
  Cria ou atualiza uma configuração.

  ## Parâmetros

    * `key` - A chave da configuração.
    * `value` - O valor da configuração.
    * `scope` - O escopo da configuração (padrão: "global").
    * `opts` - Opções adicionais (data_type, description, is_sensitive, etc.).

  ## Retorno

    * `{:ok, setting}` - Em caso de sucesso.
    * `{:error, reason}` - Se houver erros.
  """
  def upsert(key, value, scope \\ "global", opts \\ []) do
    attrs = %{
      key: key,
      value: value,
      scope: scope,
      data_type: Keyword.get(opts, :data_type) || infer_data_type(value),
      is_sensitive: Keyword.get(opts, :is_sensitive, false),
      description: Keyword.get(opts, :description, ""),
      created_by: Keyword.get(opts, :created_by, "system")
    }

    case get_by_key_and_scope(key, scope) do
      {:ok, setting} -> update(setting, attrs)
      {:error, :not_found} -> create(attrs)
    end
  end

  # Função privada para inferir o tipo de dado
  defp infer_data_type(value) when is_binary(value), do: :string
  defp infer_data_type(value) when is_integer(value), do: :integer
  defp infer_data_type(value) when is_float(value), do: :float
  defp infer_data_type(value) when is_boolean(value), do: :boolean
  defp infer_data_type(value) when is_list(value), do: :list
  defp infer_data_type(value) when is_map(value), do: :map
  defp infer_data_type(_), do: :string
end
