defmodule DeeperHub.Core.Terminal.CommandFilter do
  @moduledoc """
  Módulo responsável por filtrar comandos enviados para o terminal interativo.
  
  Este módulo define regras de segurança para determinar quais comandos podem
  ser executados via REST API, implementando uma camada de proteção contra
  a execução de código potencialmente perigoso.
  """
  
  require Logger
  
  @doc """
  Verifica se um comando está autorizado a ser executado.
  
  ## Parâmetros
    * `command` - String contendo o comando a ser validado
    * `options` - Mapa de opções que pode incluir:
      * `:context` - Contexto da execução (ex: :api, :internal)
      * `:user_id` - ID do usuário que está executando o comando
      * `:permissions` - Lista de permissões do usuário
  
  ## Retorno
    * `{:ok, command}` - Se o comando estiver autorizado
    * `{:error, reason}` - Se o comando não estiver autorizado
  
  ## Exemplos
      iex> CommandFilter.authorize("IO.puts(\"Hello\")", %{context: :api})
      {:ok, "IO.puts(\"Hello\")"}
      
      iex> CommandFilter.authorize("System.cmd(\"rm\", [\"-rf\", \"/\"])", %{context: :api})
      {:error, :unauthorized_command}
  """
  def authorize(command, options \\ %{}) do
    context = Map.get(options, :context, :api)
    
    cond do
      contains_blacklisted_term?(command) ->
        Logger.warning("Comando bloqueado por conter termo na lista negra: #{inspect(command)}")
        {:error, :blacklisted_term}
        
      not_in_allowed_modules?(command, context) ->
        Logger.warning("Comando bloqueado por usar módulo não permitido: #{inspect(command)}")
        {:error, :unauthorized_module}
        
      exceeds_max_length?(command) ->
        Logger.warning("Comando bloqueado por exceder tamanho máximo: #{String.length(command)} caracteres")
        {:error, :command_too_long}
        
      true ->
        {:ok, command}
    end
  end
  
  @doc """
  Lista de módulos permitidos para execução via API.
  Esta lista pode ser configurada nas configurações da aplicação.
  
  ## Parâmetros
    * `context` - Contexto da execução (:api, :internal)
  
  ## Retorno
    * Lista de strings com nomes de módulos permitidos
  """
  def allowed_modules(context \\ :api) do
    case context do
      :api -> 
        Application.get_env(:deeper_hub, :allowed_api_modules, [
          "IO",
          "String",
          "Enum",
          "Map",
          "List",
          "DateTime",
          "Date",
          "Time",
          "Jason",
          "DeeperHub.Core" # Exemplo, você pode restringir mais
        ])
      :internal -> 
        # Para uso interno, podemos ser mais permissivos
        Application.get_env(:deeper_hub, :allowed_internal_modules, [
          # Praticamente todos os módulos
          ""  # String vazia significa "todos permitidos"
        ])
    end
  end
  
  @doc """
  Lista de termos proibidos em comandos.
  
  ## Retorno
    * Lista de strings com termos que não devem estar presentes em comandos
  """
  def blacklisted_terms do
    Application.get_env(:deeper_hub, :blacklisted_command_terms, [
      "System.cmd",
      "File.rm",
      "File.rm_rf",
      ":os.cmd",
      "Code.eval_file",
      "Code.load_file",
      "Path.wildcard(\"/",  # Evita certos padrões perigosos
      "Port.open",
      "spawn_link"
    ])
  end
  
  @doc """
  Tamanho máximo permitido para comandos (em caracteres).
  
  ## Retorno
    * Número inteiro representando o máximo de caracteres
  """
  def max_command_length do
    Application.get_env(:deeper_hub, :max_command_length, 1000)
  end
  
  # Funções privadas auxiliares
  
  defp contains_blacklisted_term?(command) do
    Enum.any?(blacklisted_terms(), fn term -> 
      String.contains?(command, term)
    end)
  end
  
  defp not_in_allowed_modules?(command, context) do
    allowed = allowed_modules(context)
    
    # Se a lista contiver string vazia, permitimos qualquer módulo
    if Enum.member?(allowed, "") do
      false
    else
      # Análise básica para identificar o módulo sendo usado
      # Uma implementação mais robusta usaria análise de AST
      module_pattern = ~r/([A-Z][A-Za-z0-9_]*(\.[A-Z][A-Za-z0-9_]*)*)\.([a-z_][A-Za-z0-9_]*)/
      
      case Regex.scan(module_pattern, command) do
        [] -> 
          # Não encontrou nenhum padrão de módulo, vamos considerar seguro
          # (provavelmente é uma expressão simples)
          false
        matches ->
          # Verifica se todos os módulos encontrados estão na lista de permitidos
          Enum.any?(matches, fn [_, module, _, _] ->
            not Enum.any?(allowed, fn allowed_prefix ->
              String.starts_with?(module, allowed_prefix)
            end)
          end)
      end
    end
  end
  
  defp exceeds_max_length?(command) do
    String.length(command) > max_command_length()
  end
end
