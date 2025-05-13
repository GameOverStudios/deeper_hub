defmodule DeeperHub.Core.ConfigManager do
  @moduledoc """
  Módulo principal para acessar e gerenciar configurações do sistema DeeperHub.

  Este módulo é um alias para DeeperHub.Core.ConfigManager.Facade, oferecendo uma interface
  unificada para obter, definir e gerenciar configurações do sistema.
  """

  alias DeeperHub.Core.ConfigManager.Facade
  alias DeeperHub.Core.Logger

  # Delegando as funções para a fachada

  @doc """
  Obtém o valor de uma configuração.

  ## Parâmetros

    * `key` - A chave da configuração. Pode ser uma string `a.b.c` ou uma lista `[:a, :b, :c]`.
    * `scope` - O escopo da configuração (ex: "global", "user_id:123"). Se `nil`, assume "global".
    * `default` - O valor a ser retornado se a configuração não for encontrada.

  ## Exemplos

      iex> DeeperHub.Core.ConfigManager.get("app.request_timeout_ms", "global", 5000)
      5000
  """
  @spec get(String.t() | list(atom()), String.t() | nil, term() | nil) :: term()
  def get(key, scope \\ "global", default \\ nil) do
    Logger.debug("Obtendo configuração via módulo principal", %{key: key, scope: scope})
    Facade.get(key, scope, default)
  end

  @doc """
  Similar a `get/3` mas assume escopo global e aceita uma lista de chaves para construir
  o nome da configuração.

  ## Parâmetros

    * `keys` - Lista de átomos ou strings para formar a chave da configuração.
    * `default` - O valor padrão.

  ## Exemplos

      iex> DeeperHub.Core.ConfigManager.get_config([:external_services, :weather_api, :key], nil)
      nil
  """
  @spec get_config(list(atom() | String.t()), term() | nil) :: term()
  def get_config(keys, default \\ nil) do
    Logger.debug("Obtendo configuração via get_config", %{keys: inspect(keys)})
    Facade.get_config(keys, default)
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
  """
  @spec set(String.t() | list(atom()), term(), keyword()) :: {:ok, map()} | {:error, term()}
  def set(key, value, opts \\ []) do
    scope = Keyword.get(opts, :scope, "global")
    Logger.debug("Definindo configuração via módulo principal", %{key: key, scope: scope})
    Facade.set(key, value, opts)
  end

  @doc """
  Remove uma configuração.

  ## Parâmetros

    * `key` - A chave da configuração.
    * `scope` - O escopo da configuração. (Padrão: "global")
    * `opts` - Lista de opções:
      * `:deleted_by` - Identificador de quem está fazendo a remoção.
  """
  @spec delete(String.t() | list(atom()), String.t() | nil, keyword()) :: {:ok, map()} | {:error, term()}
  def delete(key, scope \\ "global", opts \\ []) do
    Logger.debug("Removendo configuração via módulo principal", %{key: key, scope: scope})
    Facade.delete(key, scope, opts)
  end

  @doc """
  Permite que um processo ou módulo se inscreva para notificações de mudanças em configurações
  que correspondam ao `event_key_pattern`.

  ## Parâmetros

    * `event_key_pattern` - Um padrão para as chaves de configuração.
    * `subscriber` - O PID ou nome do módulo que receberá as mensagens.
  """
  @spec subscribe(String.t(), pid() | module()) :: :ok | {:error, term()}
  def subscribe(event_key_pattern, subscriber) do
    Logger.debug("Registrando assinante via módulo principal", %{
      pattern: event_key_pattern,
      subscriber: inspect(subscriber)
    })
    Facade.subscribe(event_key_pattern, subscriber)
  end
end
