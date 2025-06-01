defmodule DeeperHub.Core.Terminal.OutputFormatter do
  @moduledoc """
  Formata a saída do terminal e mensagens de erro.
  """
  require Logger

  @doc """
  Filtra linhas de prompt e o marcador de fim de comando.
  """
  def clean_lines(lines, marker) when is_list(lines) do
    lines
    |> Enum.filter(fn l -> not String.contains?(l, marker) end)
    # Remove linhas que são apenas prompts de continuação (...(n)>)
    |> Enum.filter(fn l -> not Regex.match?(~r/^\s*\.\.\.\(\d+\)>\s*$/, l) end)
    # Extrai o conteúdo após os prompts de continuação (...(n)>)
    |> Enum.map(fn line ->
      cond do
        # Remove prompts de continuação no início da linha
        Regex.match?(~r/^\s*\.\.\.\(\d+\)>\s*(.*)$/, line) ->
          case Regex.run(~r/^\s*\.\.\.\(\d+\)>\s*(.*)$/, line) do
            [_, content] -> content
            _ -> line
          end
        # Remove prompts iex no início da linha
        Regex.match?(~r/^\s*iex\(\d+\)>\s*(.*)$/, line) ->
          case Regex.run(~r/^\s*iex\(\d+\)>\s*(.*)$/, line) do
            [_, content] -> content
            _ -> line
          end
        true -> line
      end
    end)
    # Remove linhas que contêm apenas pontos (como "...", ".....")
    |> Enum.filter(fn l -> not Regex.match?(~r/^\s*\.+\s*$/, l) end)
    # Remove códigos de escape ANSI e outros artefatos
    |> Enum.map(&String.trim_trailing(&1, "\e[0K")) # Remove "erase to end of line"
  end

  def clean_lines(line, marker) when is_binary(line) do
    clean_lines([line], marker) |> Enum.join()
  end


  @doc """
  Formata mensagens de erro de forma amigável.
  """
  def format_error_message(error_line, output_acc \\ []) do
    # Determina o tipo de erro baseado na linha
    error_type =
      cond do
        String.contains?(error_line, "UndefinedFunctionError") -> "ERRO: Função não definida"
        String.contains?(error_line, "CompileError") -> "ERRO: Falha na compilação"
        String.contains?(error_line, "ArithmeticError") -> "ERRO: Operação aritmética inválida"
        String.contains?(error_line, "ArgumentError") -> "ERRO: Argumento inválido"
        String.contains?(error_line, "Protocol.UndefinedError") -> "ERRO: Protocolo não implementado"
        String.contains?(error_line, "FunctionClauseError") -> "ERRO: Cláusula de função não encontrada"
        String.contains?(error_line, "SyntaxError") -> "ERRO: Sintaxe inválida"
        String.contains?(error_line, "KeyError") -> "ERRO: Chave não encontrada"
        String.contains?(error_line, "RuntimeError") -> "ERRO: Erro em tempo de execução"
        String.contains?(error_line, "ErlangError") -> "ERRO: Erro do Erlang"
        true -> "ERRO: Desconhecido"
      end

    tip =
      cond do
        String.contains?(error_line, "undefined function IO.put/1") ->
          "\nDica: Talvez você quis dizer IO.puts/1 em vez de IO.put/1"
        String.contains?(error_line, "undefined function") ->
          "\nDica: Verifique o nome da função e se o módulo está disponível"
        String.contains?(error_line, "CompileError") ->
          "\nDica: Verifique a sintaxe do código"
        true -> ""
      end

    relevant_lines =
      output_acc # Supõe-se que output_acc já está limpo de marcadores e prompts
      |> Enum.filter(fn line ->
        String.contains?(line, "Error") or String.contains?(line, "(") # Lógica simplificada
      end)
      |> Enum.take(3)
      |> Enum.join("\n")

    final_message =
      if String.trim(relevant_lines) == "" do
        "#{error_type}\n#{error_line}#{tip}"
      else
        "#{error_type}\n#{relevant_lines}\n#{error_line}#{tip}"
      end

    Logger.debug("Formatted error message: #{final_message}")
    final_message
  end
end
