defmodule Deeper_Hub.Inspector.ModuleInspector do
  @moduledoc """
  Inspetor especializado em módulos e seus metadados 📚

  Este módulo implementa o comportamento InspectorBehaviour para analisar
  módulos Elixir, extraindo informações como funções, documentação, comportamentos,
  e outros metadados relevantes.
  """

  @behaviour Deeper_Hub.Inspector.Behaviours.InspectorBehaviour

  alias Deeper_Hub.Shared.Utils.StringUtils

  @doc """
  Inspeciona um módulo e retorna informações detalhadas sobre ele 🔎

  ## Parâmetros

    * `module` - O módulo a ser inspecionado (como átomo)
    * `options` - Opções para personalizar a inspeção
      * `:include_functions` - Se deve incluir lista de funções (padrão: true)
      * `:include_docs` - Se deve incluir a documentação (padrão: true)
      * `:include_behaviours` - Se deve incluir comportamentos implementados (padrão: true)
      * `:include_attributes` - Se deve incluir atributos do módulo (padrão: true)
      * `:include_types` - Se deve incluir definições de tipos (padrão: true)

  ## Retorno

  Retorna um mapa com informações detalhadas sobre o módulo.

  ## Exemplos

      iex> Deeper_Hub.Inspector.ModuleInspector.inspect_module(Enum)
      %{
        type: :module,
        name: Enum,
        docs: "...",
        functions: [...],
        behaviours: [...],
        attributes: [...],
        types: [...]
      }
  """
  @impl true
  def inspect_module(module, options \\ []) do
    # Verificar se o módulo existe
    unless is_atom(module) and Code.ensure_loaded?(module) do
      return_error("Módulo #{inspect(module)} não encontrado ou não carregado")
    end

    include_functions = Keyword.get(options, :include_functions, true)
    include_docs = Keyword.get(options, :include_docs, true)
    include_behaviours = Keyword.get(options, :include_behaviours, true)
    include_attributes = Keyword.get(options, :include_attributes, true)
    include_types = Keyword.get(options, :include_types, true)

    # Coletar informações básicas
    result = %{
      type: :module,
      name: module
    }

    # Adicionar documentação se solicitado
    result =
      if include_docs do
        docs = get_module_docs(module)
        Map.put(result, :docs, docs)
      else
        result
      end

    # Adicionar funções se solicitado
    result =
      if include_functions do
        functions = get_module_functions(module)
        Map.put(result, :functions, functions)
      else
        result
      end

    # Adicionar comportamentos se solicitado
    result =
      if include_behaviours do
        behaviours = get_module_behaviours(module)
        Map.put(result, :behaviours, behaviours)
      else
        result
      end

    # Adicionar atributos se solicitado
    result =
      if include_attributes do
        attributes = get_module_attributes(module)
        Map.put(result, :attributes, attributes)
      else
        result
      end

    # Adicionar tipos se solicitado
    result =
      if include_types do
        types = get_module_types(module)
        Map.put(result, :types, types)
      else
        result
      end

    # Verificar se é uma struct
    result =
      if struct?(module) do
        struct_info = get_struct_info(module)
        Map.put(result, :struct, struct_info)
      else
        result
      end

    result
  end

  @doc """
  Verifica se o elemento é um módulo válido ✅

  ## Parâmetros

    * `element` - O elemento a ser verificado

  ## Retorno

  Retorna `true` se o elemento for um módulo, ou `false` caso contrário.

  ## Exemplos

      iex> Deeper_Hub.Inspector.ModuleInspector.supported?(Enum)
      true

      iex> Deeper_Hub.Inspector.ModuleInspector.supported?("not a module")
      false
  """
  @impl true
  def supported?(element) do
    is_atom(element) and Code.ensure_loaded?(element)
  end

  @doc """
  Retorna o tipo de elemento que este inspetor suporta 📋

  ## Retorno

  Retorna o átomo `:module`.
  """
  @impl true
  def element_type(), do: :module

  @doc """
  Extrai metadados específicos do módulo inspecionado 📊

  ## Parâmetros

    * `module` - O módulo do qual extrair metadados
    * `options` - Opções para personalizar a extração

  ## Retorno

  Retorna um mapa com metadados do módulo.
  """
  @impl true
  def extract_metadata(module, options \\ []) do
    if is_atom(module) and Code.ensure_loaded?(module) do
      # Extrair informações básicas
      %{
        name: module,
        is_struct: struct?(module),
        function_count: length(get_module_functions(module)),
        has_docs: has_docs?(module)
      }
    else
      %{type: :unknown}
    end
  end

  @doc """
  Formata o resultado da inspeção para exibição 🖥️

  ## Parâmetros

    * `inspection_result` - O resultado da inspeção
    * `format` - O formato desejado para a saída (:text, :json, :html)

  ## Retorno

  Retorna uma string formatada com o resultado da inspeção.
  """
  @impl true
  def format_result(inspection_result, format \\ :text) do
    case format do
      :text -> format_as_text(inspection_result)
      :json -> format_as_json(inspection_result)
      :html -> format_as_html(inspection_result)
      _ -> format_as_text(inspection_result)
    end
  end

  # Funções privadas

  defp get_module_docs(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, content_type, %{"en" => docs}, _, _} ->
        docs

      {:docs_v1, _, _, content_type, docs, _, _} when is_binary(docs) ->
        docs

      _ ->
        "Documentação não disponível"
    end
  rescue
    _ -> "Erro ao obter documentação"
  end

  defp get_module_functions(module) do
    try do
      # Obter funções públicas
      public_functions =
        module.__info__(:functions)
        |> Enum.map(fn {name, arity} ->
          %{name: name, arity: arity, type: :public}
        end)

      # Tentar obter funções privadas (nem sempre disponível)
      private_functions =
        try do
          module.__info__(:macros)
          |> Enum.map(fn {name, arity} ->
            %{name: name, arity: arity, type: :macro}
          end)
        rescue
          _ -> []
        end

      public_functions ++ private_functions
    rescue
      _ -> []
    end
  end

  defp get_module_behaviours(module) do
    try do
      module.__info__(:attributes)
      |> Enum.filter(fn {key, _} -> key == :behaviour end)
      |> Enum.flat_map(fn {_, values} -> values end)
    rescue
      _ -> []
    end
  end

  defp get_module_attributes(module) do
    try do
      module.__info__(:attributes)
      |> Enum.reject(fn {key, _} -> key in [:behaviour, :doc, :impl, :spec, :type] end)
      |> Enum.map(fn {key, values} -> {key, values} end)
      |> Enum.into(%{})
    rescue
      _ -> %{}
    end
  end

  defp get_module_types(module) do
    try do
      case Code.Typespec.fetch_types(module) do
        {:ok, types} ->
          Enum.map(types, fn type ->
            case type do
              {:type, {name, definition, args}} ->
                %{
                  kind: :type,
                  name: name,
                  definition: Macro.to_string(definition),
                  args: args
                }

              {:opaque, {name, definition, args}} ->
                %{
                  kind: :opaque,
                  name: name,
                  definition: Macro.to_string(definition),
                  args: args
                }

              {:typep, {name, definition, args}} ->
                %{
                  kind: :typep,
                  name: name,
                  definition: Macro.to_string(definition),
                  args: args
                }

              _ ->
                %{kind: :unknown, raw: inspect(type)}
            end
          end)

        _ ->
          []
      end
    rescue
      _ -> []
    end
  end

  defp struct?(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :__struct__, 0)
  end

  defp get_struct_info(module) do
    try do
      struct = module.__struct__()
      keys = Map.keys(struct) -- [:__struct__]

      %{
        fields: keys,
        default_values: Map.take(struct, keys)
      }
    rescue
      _ -> %{error: "Erro ao obter informações da struct"}
    end
  end

  defp has_docs?(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, _} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  defp format_as_text(result) do
    case result do
      %{type: :module, name: name} = info ->
        header = "Módulo: #{inspect(name)}"

        docs =
          case info[:docs] do
            nil -> ""
            docs -> "\n\nDocumentação:\n#{StringUtils.truncate(docs, 500)}"
          end

        functions =
          case info[:functions] do
            nil ->
              ""

            [] ->
              "\n\nFunções: Nenhuma função encontrada"

            functions ->
              functions_text =
                functions
                |> Enum.map(fn %{name: name, arity: arity, type: type} ->
                  "  - #{name}/#{arity} (#{type})"
                end)
                |> Enum.join("\n")

              "\n\nFunções:\n#{functions_text}"
          end

        behaviours =
          case info[:behaviours] do
            nil ->
              ""

            [] ->
              ""

            behaviours ->
              behaviours_text =
                behaviours
                |> Enum.map(&inspect/1)
                |> Enum.join("\n  - ")

              "\n\nImplementa comportamentos:\n  - #{behaviours_text}"
          end

        struct_info =
          case info[:struct] do
            nil ->
              ""

            %{fields: fields} ->
              fields_text =
                fields
                |> Enum.map(&inspect/1)
                |> Enum.join(", ")

              "\n\nStruct com campos: #{fields_text}"
          end

        types =
          case info[:types] do
            nil ->
              ""

            [] ->
              ""

            types ->
              types_text =
                types
                |> Enum.map(fn type ->
                  "  - #{type[:name]} (#{type[:kind]}): #{type[:definition]}"
                end)
                |> Enum.join("\n")

              "\n\nTipos definidos:\n#{types_text}"
          end

        "#{header}#{docs}#{functions}#{behaviours}#{struct_info}#{types}"

      {:error, message} ->
        "Erro: #{message}"

      _ ->
        "Resultado de inspeção desconhecido"
    end
  end

  defp format_as_json(result) do
    Jason.encode!(result, pretty: true)
  rescue
    e -> "Erro ao formatar como JSON: #{inspect(e)}"
  end

  defp format_as_html(result) do
    case result do
      %{type: :module, name: name} = info ->
        """
        <div class="module-inspector">
          <h3>Módulo: #{inspect(name)}</h3>

          #{if info[:docs], do: "<div class=\"docs\"><h4>Documentação:</h4><pre>#{escape_html(info[:docs])}</pre></div>", else: ""}

          #{format_functions_html(info[:functions])}

          #{format_behaviours_html(info[:behaviours])}

          #{format_struct_html(info[:struct])}

          #{format_types_html(info[:types])}
        </div>
        """

      {:error, message} ->
        "<div class=\"module-inspector error\"><p>Erro: #{escape_html(message)}</p></div>"

      _ ->
        "<div class=\"module-inspector unknown\"><p>Resultado de inspeção desconhecido</p></div>"
    end
  end

  defp format_functions_html(functions) do
    case functions do
      nil ->
        ""

      [] ->
        "<p>Funções: Nenhuma função encontrada</p>"

      functions ->
        """
        <div class="functions">
          <h4>Funções:</h4>
          <ul>
            #{Enum.map(functions, fn %{name: name, arity: arity, type: type} -> "<li><code>#{name}/#{arity}</code> <span class=\"badge\">#{type}</span></li>" end) |> Enum.join("\n")}
          </ul>
        </div>
        """
    end
  end

  defp format_behaviours_html(behaviours) do
    case behaviours do
      nil ->
        ""

      [] ->
        ""

      behaviours ->
        """
        <div class="behaviours">
          <h4>Implementa comportamentos:</h4>
          <ul>
            #{Enum.map(behaviours, fn behaviour -> "<li><code>#{inspect(behaviour)}</code></li>" end) |> Enum.join("\n")}
          </ul>
        </div>
        """
    end
  end

  defp format_struct_html(struct_info) do
    case struct_info do
      nil ->
        ""

      %{fields: fields} ->
        """
        <div class="struct">
          <h4>Struct com campos:</h4>
          <ul>
            #{Enum.map(fields, fn field -> "<li><code>#{inspect(field)}</code></li>" end) |> Enum.join("\n")}
          </ul>
        </div>
        """

      _ ->
        ""
    end
  end

  defp format_types_html(types) do
    case types do
      nil ->
        ""

      [] ->
        ""

      types ->
        """
        <div class="types">
          <h4>Tipos definidos:</h4>
          <ul>
            #{Enum.map(types, fn type -> "<li><code>#{type[:name]}</code> <span class=\"badge\">#{type[:kind]}</span>: <code>#{escape_html(type[:definition])}</code></li>" end) |> Enum.join("\n")}
          </ul>
        </div>
        """
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

  defp return_error(message) do
    {:error, message}
  end
end
