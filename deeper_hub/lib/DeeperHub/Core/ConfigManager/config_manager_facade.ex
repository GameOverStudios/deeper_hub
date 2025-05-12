defmodule DeeperHub.Core.ConfigManager.Facade do
  @moduledoc """
  Fachada pública para acessar e gerenciar configurações do sistema DeeperHub.

  Este módulo oferece uma interface unificada para obter, definir e gerenciar configurações,
  independentemente de onde elas são armazenadas (arquivos de configuração, banco de dados,
  variáveis de ambiente).
  """

  alias DeeperHub.Core.ConfigManager.Server

  @doc """
  Obtém o valor de uma configuração.

  ## Parâmetros

    * `key` - A chave da configuração. Pode ser uma string `a.b.c` ou uma lista `[:a, :b, :c]`.
    * `scope` - O escopo da configuração (ex: "global", "user_id:123"). Se `nil`, assume "global".
    * `default` - O valor a ser retornado se a configuração não for encontrada.

  ## Exemplos

      iex> DeeperHub.Core.ConfigManager.Facade.get("app.request_timeout_ms", "global", 5000)
      5000

      iex> DeeperHub.Core.ConfigManager.Facade.get([:features, :new_reporting, :enabled], "tenant:abc", false)
      false
  """
  @spec get(String.t() | list(atom()), String.t() | nil, term() | nil) :: term()
  def get(key, scope \\ "global", default \\ nil) do
    normalized_key = normalize_key(key)
    Server.get(normalized_key, scope, default)
  end

  @doc """
  Similar a `get/3` mas assume escopo global e aceita uma lista de chaves para construir
  o nome da configuração.

  ## Parâmetros

    * `keys` - Lista de átomos ou strings para formar a chave da configuração.
    * `default` - O valor padrão.

  ## Exemplos

      iex> DeeperHub.Core.ConfigManager.Facade.get_config([:external_services, :weather_api, :key], nil)
      nil
  """
  @spec get_config(list(atom() | String.t()), term() | nil) :: term()
  def get_config(keys, default \\ nil) do
    get(keys, "global", default)
  end

  @doc """
  Define ou atualiza o valor de uma configuração.

  ## Parâmetros

    * `key` - A chave da configuração.
    * `value` - O novo valor para a configuração.
    * `opts` - Lista de opções:
      * `:scope` - O escopo da configuração. (Padrão: "global")
      * `:data_type` - O tipo de dado do valor.
      * `:description` - Uma descrição da configuração.
      * `:is_sensitive` - Indica se a configuração contém dados sensíveis. (Padrão: false)
      * `:created_by` - Identificador de quem está fazendo a alteração.

  ## Exemplos

      iex> opts = [
      ...>   scope: "global",
      ...>   data_type: :integer,
      ...>   description: "Timeout para requisições à API externa X.",
      ...>   is_sensitive: false,
      ...>   created_by: "admin_user_id"
      ...> ]
      iex> DeeperHub.Core.ConfigManager.Facade.set("external_api.timeout", 10000, opts)
      {:ok, %{key: "external_api.timeout", value: 10000}}
  """
  @spec set(String.t() | list(atom()), term(), keyword()) :: {:ok, map()} | {:error, term()}
  def set(key, value, opts \\ []) do
    normalized_key = normalize_key(key)
    scope = Keyword.get(opts, :scope, "global")

    Server.set(normalized_key, value, scope, opts)
  end

  @doc """
  Remove uma configuração.

  ## Parâmetros

    * `key` - A chave da configuração.
    * `scope` - O escopo da configuração. (Padrão: "global")
    * `opts` - Lista de opções:
      * `:deleted_by` - Identificador de quem está fazendo a remoção.

  ## Exemplos

      iex> DeeperHub.Core.ConfigManager.Facade.delete("old_feature.enabled", "global", deleted_by: "cleanup_script")
      {:ok, %{key: "old_feature.enabled"}}
  """
  @spec delete(String.t() | list(atom()), String.t() | nil, keyword()) :: {:ok, map()} | {:error, term()}
  def delete(key, scope \\ "global", opts \\ []) do
    normalized_key = normalize_key(key)
    Server.delete(normalized_key, scope, opts)
  end

  @doc """
  Permite que um processo ou módulo se inscreva para notificações de mudanças em configurações
  que correspondam ao `event_key_pattern`.

  ## Parâmetros

    * `event_key_pattern` - Um padrão para as chaves de configuração.
    * `subscriber` - O PID ou nome do módulo que receberá as mensagens.

  ## Exemplos

      iex> DeeperHub.Core.ConfigManager.Facade.subscribe("notifications.smtp.*", self())
      :ok
  """
  @spec subscribe(String.t(), pid() | module()) :: :ok | {:error, term()}
  def subscribe(event_key_pattern, subscriber) do
    Server.subscribe(event_key_pattern, subscriber)
  end

  # Função privada para normalizar a chave
  defp normalize_key(key) when is_list(key) do
    Enum.map_join(key, ".", fn
      k when is_atom(k) -> Atom.to_string(k)
      k when is_binary(k) -> k
    end)
  end

  defp normalize_key(key) when is_binary(key), do: key
  defp normalize_key(key) when is_atom(key), do: Atom.to_string(key)
end
