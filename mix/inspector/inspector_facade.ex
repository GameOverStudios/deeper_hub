defmodule Deeper_Hub.Inspector.InspectorFacade do
  @moduledoc """
  Fachada para o sistema de inspeção de código 🔍

  Este módulo fornece uma interface unificada para o sistema de inspeção,
  coordenando o uso dos diferentes inspetores especializados para analisar
  elementos do código como funções, módulos e especificações de tipo.
  """

  alias Deeper_Hub.Inspector.FunctionInspector
  alias Deeper_Hub.Inspector.ModuleInspector
  alias Deeper_Hub.Inspector.TypeSpecInspector

  @doc """
  Inspeciona um elemento e retorna informações detalhadas sobre ele 🔎

  Detecta automaticamente o tipo de elemento e utiliza o inspetor apropriado.

  ## Parâmetros

    * `element` - O elemento a ser inspecionado (módulo, função ou typespec)
    * `options` - Opções para personalizar a inspeção

  ## Retorno

  Retorna um mapa com informações detalhadas sobre o elemento inspecionado.

  ## Exemplos

      iex> Deeper_Hub.Inspector.InspectorFacade.inspect_element(Enum)
      %{type: :module, name: Enum, ...}

      iex> Deeper_Hub.Inspector.InspectorFacade.inspect_element({Enum, :map, 2})
      %{type: :function, module: Enum, name: :map, ...}
  """
  @spec inspect_element(any(), keyword()) :: map() | {:error, String.t()}
  def inspect_element(element, options \\ []) do
    # Detectar o tipo de elemento e usar o inspetor apropriado
    cond do
      ModuleInspector.supported?(element) ->
        ModuleInspector.inspect_module(element, options)

      FunctionInspector.supported?(element) ->
        FunctionInspector.inspect_function(element, options)

      TypeSpecInspector.supported?(element) ->
        TypeSpecInspector.inspect_typespec(element, options)

      true ->
        {:error, "Tipo de elemento não suportado: #{inspect(element)}"}
    end
  end

  @doc """
  Formata o resultado da inspeção para exibição 🖥️

  ## Parâmetros

    * `inspection_result` - O resultado da inspeção
    * `format` - O formato desejado para a saída (:text, :json, :html)

  ## Retorno

  Retorna uma string formatada com o resultado da inspeção.

  ## Exemplos

      iex> result = Deeper_Hub.Inspector.InspectorFacade.inspect_element(Enum)
      iex> Deeper_Hub.Inspector.InspectorFacade.format_result(result, :text)
      "Módulo: Enum\n..."
  """
  @spec format_result(map() | {:error, String.t()}, atom()) :: String.t()
  def format_result(inspection_result, format \\ :text) do
    case inspection_result do
      {:error, message} ->
        format_error(message, format)

      %{type: :module} = result ->
        ModuleInspector.format_result(result, format)

      %{type: :function} = result ->
        FunctionInspector.format_result(result, format)

      %{type: :typespec} = result ->
        TypeSpecInspector.format_result(result, format)

      _ ->
        format_error("Resultado de inspeção desconhecido", format)
    end
  end

  @doc """
  Lista todos os inspetores disponíveis no sistema 📋

  ## Retorno

  Retorna uma lista de mapas com informações sobre os inspetores disponíveis.

  ## Exemplos

      iex> Deeper_Hub.Inspector.InspectorFacade.list_inspectors()
      [
        %{name: "ModuleInspector", type: :module, description: "..."},
        %{name: "FunctionInspector", type: :function, description: "..."},
        %{name: "TypeSpecInspector", type: :typespec, description: "..."}
      ]
  """
  @spec list_inspectors() :: list(map())
  def list_inspectors do
    [
      %{
        name: "ModuleInspector",
        type: :module,
        description: "Inspetor especializado em módulos Elixir"
      },
      %{
        name: "FunctionInspector",
        type: :function,
        description: "Inspetor especializado em funções e seus metadados"
      },
      %{
        name: "TypeSpecInspector",
        type: :typespec,
        description: "Inspetor especializado em especificações de tipo (typespecs)"
      }
    ]
  end

  @doc """
  Obtém o inspetor apropriado para um determinado tipo de elemento 🔍

  ## Parâmetros

    * `element_type` - O tipo de elemento (:module, :function, :typespec)

  ## Retorno

  Retorna o módulo do inspetor apropriado ou nil se não houver inspetor para o tipo.

  ## Exemplos

      iex> Deeper_Hub.Inspector.InspectorFacade.get_inspector_for(:module)
      Deeper_Hub.Inspector.ModuleInspector
  """
  @spec get_inspector_for(atom()) :: module() | nil
  def get_inspector_for(element_type) do
    case element_type do
      :module -> ModuleInspector
      :function -> FunctionInspector
      :typespec -> TypeSpecInspector
      _ -> nil
    end
  end

  @doc """
  Verifica se um elemento é suportado por algum dos inspetores disponíveis ✅

  ## Parâmetros

    * `element` - O elemento a ser verificado

  ## Retorno

  Retorna `true` se o elemento for suportado por algum inspetor, ou `false` caso contrário.

  ## Exemplos

      iex> Deeper_Hub.Inspector.InspectorFacade.supported?(Enum)
      true

      iex> Deeper_Hub.Inspector.InspectorFacade.supported?({:not, :supported})
      false
  """
  @spec supported?(any()) :: boolean()
  def supported?(element) do
    ModuleInspector.supported?(element) or
      FunctionInspector.supported?(element) or
      TypeSpecInspector.supported?(element)
  end

  # Funções privadas

  defp format_error(message, format) do
    case format do
      :text -> "Erro: #{message}"
      :json -> Jason.encode!(%{error: message})
      :html -> "<div class=\"error\"><p>Erro: #{escape_html(message)}</p></div>"
      _ -> "Erro: #{message}"
    end
  end

  defp escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp escape_html(other), do: escape_html(inspect(other))
end
