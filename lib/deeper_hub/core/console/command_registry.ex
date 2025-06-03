defmodule DeeperHub.Core.Console.CommandRegistry do
  @moduledoc """
  Registro de comandos disponíveis para o console interativo.

  Este módulo gerencia o registro de comandos que podem ser executados
  no console, incluindo metadados como descrição, argumentos esperados
  e funções de execução.
  """

  require Logger

  @doc """
  Registra um novo comando no registro.

  ## Parâmetros
    * `name` - Nome do comando (string)
    * `description` - Descrição do comando
    * `handler` - Função que será executada quando o comando for chamado
    * `options` - Opções adicionais como argumentos esperados, permissões, etc.

  ## Retorno
    * `:ok` - Comando registrado com sucesso
    * `{:error, reason}` - Falha no registro do comando
  """
  def register_command(name, description, _handler, _options \\ %{}) do
    # Esta é uma implementação inicial simplificada.
    # Em implementações futuras, isso poderia salvar em um agente ou outro mecanismo
    # de armazenamento para manter os comandos registrados entre reinicializações.
    Logger.info("Comando '#{name}' registrado: #{description}")
    :ok
  end

  @doc """
  Retorna uma lista de todos os comandos disponíveis.

  ## Retorno
    * Lista de mapas contendo informações sobre os comandos
  """
  def list_commands do
    # Comandos básicos embutidos
    [
      %{
        name: "help",
        description: "Exibe a lista de comandos disponíveis com suas descrições",
        usage: "help [comando]"
      },
      %{
        name: "info",
        description: "Exibe informações sobre a sessão atual",
        usage: "info"
      },
      %{
        name: "clear",
        description: "Limpa o histórico de comandos da sessão",
        usage: "clear"
      },
      %{
        name: "history",
        description: "Mostra o histórico de comandos da sessão",
        usage: "history"
      },
      %{
        name: "quit",
        description: "Encerra a sessão atual",
        usage: "quit"
      },
      %{
        name: "exit",
        description: "Encerra a sessão atual (alias para quit)",
        usage: "exit"
      }
    ]
  end

  @doc """
  Procura por um comando específico pelo nome.

  ## Parâmetros
    * `name` - Nome do comando a ser buscado

  ## Retorno
    * `{:ok, command}` - Informações sobre o comando encontrado
    * `{:error, :not_found}` - Comando não encontrado
  """
  def find_command(name) when is_binary(name) do
    command = Enum.find(list_commands(), fn cmd -> cmd.name == name end)

    if command do
      {:ok, command}
    else
      {:error, :not_found}
    end
  end

  @doc """
  Valida se um comando existe e pode ser executado.

  ## Parâmetros
    * `name` - Nome do comando
    * `context` - Contexto de execução (opcional)

  ## Retorno
    * `{:ok, command}` - Comando é válido
    * `{:error, reason}` - Comando inválido
  """
  def validate_command(name, _context \\ nil) do
    case find_command(name) do
      {:ok, command} ->
        # Aqui poderia ter lógica adicional para verificar permissões
        # baseadas no contexto, por exemplo
        {:ok, command}
      error -> error
    end
  end

  @doc """
  Gera uma mensagem de ajuda detalhada para um comando específico.

  ## Parâmetros
    * `name` - Nome do comando

  ## Retorno
    * `{:ok, help_text}` - Texto de ajuda para o comando
    * `{:error, reason}` - Erro caso o comando não seja encontrado
  """
  def get_command_help(name) do
    case find_command(name) do
      {:ok, command} ->
        help_text = """
        === AJUDA: #{command.name} ===

        #{command.description}

        Uso: #{command.usage}
        """
        {:ok, help_text}

      {:error, :not_found} ->
        {:error, "Comando '#{name}' não encontrado."}
    end
  end
end
