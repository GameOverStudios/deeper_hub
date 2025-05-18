defmodule DeeperHub.Inspector.TypeSpecInspector do
  @moduledoc """
  Inspetor especializado em especificações de tipo (typespecs) 📝

  Este módulo implementa o comportamento InspectorBehaviour para analisar
  especificações de tipo em Elixir, incluindo @type, @spec, @callback e outros.
  """

  @behaviour DeeperHub.Inspector.Behaviours.InspectorBehaviour

  alias DeeperHub.Shared.Utils.StringUtils

  @doc """
  Inspeciona uma especificação de tipo e retorna informações detalhadas sobre ela 🔎

  ## Parâmetros

    * `typespec` - A especificação de tipo a ser inspecionada, como {módulo, tipo, nome, aridade}
    * `options` - Opções para personalizar a inspeção
      * `:include_related` - Se deve incluir tipos relacionados (padrão: false)

  ## Retorno

  Retorna um mapa com informações detalhadas sobre a especificação de tipo.

  ## Exemplos

      iex> DeeperHub.Inspector.TypeSpecInspector.inspect_typespec({Enum, :type, :t, 0})
      %{
        type: :typespec,
        kind: :type,
        module: Enum,
        name: :t,
        arity: 0,
        definition: "...",
        related_types: [...]
      }
  """
  @impl true
  def inspect_typespec(typespec, options \\ []) do
    include_related = Keyword.get(options, :include_related, false)

    case typespec do
      {module, kind, name, arity}
      when is_atom(module) and is_atom(kind) and is_atom(name) and is_integer(arity) ->
        inspect_typespec(module, kind, name, arity, include_related)

      _ ->
        {:error, "Formato de especificação de tipo não suportado"}
    end
  end

  @doc """
  Verifica se o elemento é uma especificação de tipo válida ✅

  ## Parâmetros

    * `element` - O elemento a ser verificado

  ## Retorno

  Retorna `true` se o elemento for uma especificação de tipo válida, ou `false` caso contrário.

  ## Exemplos

      iex> DeeperHub.Inspector.TypeSpecInspector.supported?({Enum, :type, :t, 0})
      true

      iex> DeeperHub.Inspector.TypeSpecInspector.supported?("not a typespec")
      false
  """
  @impl true
  def supported?(element) do
    case element do
      {module, kind, name, arity}
      when is_atom(module) and is_atom(kind) and is_atom(name) and is_integer(arity) ->
        kind in [:type, :opaque, :typep, :spec, :callback, :macrocallback]

      _ ->
        false
    end
  end

  @doc """
  Retorna o tipo de elemento que este inspetor suporta 📋

  ## Retorno

  Retorna o átomo `:typespec`.
  """
  @impl true
  def element_type(), do: :typespec

  @doc """
  Extrai metadados específicos da especificação de tipo inspecionada 📊

  ## Parâmetros

    * `typespec` - A especificação de tipo da qual extrair metadados
    * `options` - Opções para personalizar a extração

  ## Retorno

  Retorna um mapa com metadados da especificação de tipo.
  """
  @impl true
  def extract_metadata(typespec, options \\ []) do
    case typespec do
      {module, kind, name, arity}
      when is_atom(module) and is_atom(kind) and is_atom(name) and is_integer(arity) ->
        %{
          module: module,
          kind: kind,
          name: name,
          arity: arity
        }

      _ ->
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

  defp inspect_typespec(module, kind, name, arity, include_related) do
    # Verificar se o módulo existe
    unless Code.ensure_loaded?(module) do
      return_error("Módulo #{inspect(module)} não encontrado ou não carregado")
    end

    # Obter a definição do tipo com base no tipo de especificação
    definition =
      case kind do
        :type -> get_type_definition(module, name, arity)
        :opaque -> get_opaque_definition(module, name, arity)
        :typep -> get_typep_definition(module, name, arity)
        :spec -> get_spec_definition(module, name, arity)
        :callback -> get_callback_definition(module, name, arity)
        :macrocallback -> get_macrocallback_definition(module, name, arity)
        _ -> return_error("Tipo de especificação não suportado: #{inspect(kind)}")
      end

    case definition do
      {:error, reason} ->
        {:error, reason}

      definition ->
        # Construir o resultado básico
        result = %{
          type: :typespec,
          kind: kind,
          module: module,
          name: name,
          arity: arity,
          definition: definition
        }

        # Adicionar tipos relacionados se solicitado
        if include_related and kind in [:type, :opaque, :typep] do
          related = get_related_types(module, definition)
          Map.put(result, :related_types, related)
        else
          result
        end
    end
  end

  defp get_type_definition(module, name, arity) do
    try do
      case Code.Typespec.fetch_types(module) do
        {:ok, types} ->
          # Filtrar para encontrar o tipo específico
          type =
            Enum.find(types, fn
              {:type, {^name, _, args}} when length(args) == arity -> true
              _ -> false
            end)

          case type do
            {:type, {^name, definition, _}} ->
              format_typespec(definition)

            _ ->
              {:error, "Tipo #{name}/#{arity} não encontrado no módulo #{inspect(module)}"}
          end

        _ ->
          {:error, "Nenhum tipo encontrado no módulo #{inspect(module)}"}
      end
    rescue
      e -> {:error, "Erro ao obter definição de tipo: #{inspect(e)}"}
    end
  end

  defp get_opaque_definition(module, name, arity) do
    try do
      case Code.Typespec.fetch_types(module) do
        {:ok, types} ->
          # Filtrar para encontrar o tipo opaque específico
          type =
            Enum.find(types, fn
              {:opaque, {^name, _, args}} when length(args) == arity -> true
              _ -> false
            end)

          case type do
            {:opaque, {^name, definition, _}} ->
              format_typespec(definition)

            _ ->
              {:error, "Tipo opaque #{name}/#{arity} não encontrado no módulo #{inspect(module)}"}
          end

        _ ->
          {:error, "Nenhum tipo encontrado no módulo #{inspect(module)}"}
      end
    rescue
      e -> {:error, "Erro ao obter definição de tipo opaque: #{inspect(e)}"}
    end
  end

  defp get_typep_definition(module, name, arity) do
    try do
      case Code.Typespec.fetch_types(module) do
        {:ok, types} ->
          # Filtrar para encontrar o tipo privado específico
          type =
            Enum.find(types, fn
              {:typep, {^name, _, args}} when length(args) == arity -> true
              _ -> false
            end)

          case type do
            {:typep, {^name, definition, _}} ->
              format_typespec(definition)

            _ ->
              {:error,
               "Tipo privado #{name}/#{arity} não encontrado no módulo #{inspect(module)}"}
          end

        _ ->
          {:error, "Nenhum tipo encontrado no módulo #{inspect(module)}"}
      end
    rescue
      e -> {:error, "Erro ao obter definição de tipo privado: #{inspect(e)}"}
    end
  end

  defp get_spec_definition(module, name, arity) do
    try do
      case Code.Typespec.fetch_specs(module) do
        {:ok, specs} ->
          # Filtrar para encontrar a spec específica
          spec =
            Enum.find(specs, fn
              {{^name, ^arity}, _} -> true
              _ -> false
            end)

          case spec do
            {{^name, ^arity}, definitions} ->
              # Uma spec pode ter múltiplas definições (cláusulas)
              definitions
              |> Enum.map(&format_typespec/1)
              |> Enum.join("\n")

            _ ->
              {:error, "Spec #{name}/#{arity} não encontrada no módulo #{inspect(module)}"}
          end

        _ ->
          {:error, "Nenhuma spec encontrada no módulo #{inspect(module)}"}
      end
    rescue
      e -> {:error, "Erro ao obter definição de spec: #{inspect(e)}"}
    end
  end

  defp get_callback_definition(module, name, arity) do
    try do
      case Code.Typespec.fetch_callbacks(module) do
        {:ok, callbacks} ->
          # Filtrar para encontrar o callback específico
          callback =
            Enum.find(callbacks, fn
              {{^name, ^arity}, _} -> true
              _ -> false
            end)

          case callback do
            {{^name, ^arity}, definitions} ->
              # Um callback pode ter múltiplas definições
              definitions
              |> Enum.map(&format_typespec/1)
              |> Enum.join("\n")

            _ ->
              {:error, "Callback #{name}/#{arity} não encontrado no módulo #{inspect(module)}"}
          end

        _ ->
          {:error, "Nenhum callback encontrado no módulo #{inspect(module)}"}
      end
    rescue
      e -> {:error, "Erro ao obter definição de callback: #{inspect(e)}"}
    end
  end

  defp get_macrocallback_definition(module, name, arity) do
    try do
      case Code.Typespec.fetch_callbacks(module) do
        {:ok, callbacks} ->
          # Filtrar para encontrar o macrocallback específico
          # Nota: macrocallbacks são armazenados junto com callbacks, mas têm um marcador especial
          callback =
            Enum.find(callbacks, fn
              {{^name, ^arity}, [definition | _]} ->
                # Verificar se é um macrocallback (isso é uma heurística, não há uma maneira direta)
                is_macrocallback?(definition)

              _ ->
                false
            end)

          case callback do
            {{^name, ^arity}, definitions} ->
              definitions
              |> Enum.map(&format_typespec/1)
              |> Enum.join("\n")

            _ ->
              {:error,
               "Macrocallback #{name}/#{arity} não encontrado no módulo #{inspect(module)}"}
          end

        _ ->
          {:error, "Nenhum macrocallback encontrado no módulo #{inspect(module)}"}
      end
    rescue
      e -> {:error, "Erro ao obter definição de macrocallback: #{inspect(e)}"}
    end
  end

  # Heurística para identificar macrocallbacks
  # Isso é uma aproximação, pois não há uma maneira direta de distingui-los
  defp is_macrocallback?(definition) do
    # Tentar identificar padrões comuns em macrocallbacks
    # Geralmente, eles têm um contexto específico ou coordenam AST
    inspect(definition) =~ "Macro.t" or inspect(definition) =~ "term" or
      inspect(definition) =~ "ast"
  end

  defp get_related_types(module, definition) do
    # Analisar a definição para encontrar referências a outros tipos
    # Esta é uma implementação simplificada e pode não capturar todos os tipos relacionados
    definition_str = to_string(definition)

    # Procurar por padrões como t() ou t(a, b) que indicam referências a tipos
    type_refs =
      Regex.scan(~r/\b([a-z_][a-zA-Z0-9_]*)\(([^)]*)\)/, definition_str)
      |> Enum.map(fn [_, name, args] ->
        arity = if args == "", do: 0, else: String.split(args, ",") |> length
        {String.to_atom(name), arity}
      end)
      |> Enum.uniq()

    # Tentar encontrar os tipos referenciados no mesmo módulo
    Enum.map(type_refs, fn {name, arity} ->
      case get_type_definition(module, name, arity) do
        {:error, _} -> %{name: name, arity: arity, found: false}
        definition -> %{name: name, arity: arity, found: true, definition: definition}
      end
    end)
  end

  defp format_typespec(typespec) do
    try do
      Macro.to_string(typespec)
    rescue
      _ -> inspect(typespec)
    end
  end

  defp format_as_text(result) do
    case result do
      %{type: :typespec, kind: kind, module: module, name: name, arity: arity} = info ->
        kind_str =
          case kind do
            :type -> "Tipo"
            :opaque -> "Tipo opaco"
            :typep -> "Tipo privado"
            :spec -> "Especificação"
            :callback -> "Callback"
            :macrocallback -> "Macrocallback"
            _ -> "Typespec"
          end

        header = "#{kind_str}: #{inspect(module)}.#{name}/#{arity}"

        definition =
          case info[:definition] do
            nil -> "Definição não disponível"
            {:error, msg} -> "Erro: #{msg}"
            definition -> definition
          end

        related =
          case info[:related_types] do
            nil ->
              ""

            [] ->
              ""

            related ->
              related_text =
                related
                |> Enum.map(fn
                  %{name: name, arity: arity, found: true, definition: def} ->
                    "  - #{name}/#{arity}: #{StringUtils.truncate(def, 100)}"

                  %{name: name, arity: arity} ->
                    "  - #{name}/#{arity} (não encontrado)"
                end)
                |> Enum.join("\n")

              "\n\nTipos relacionados:\n#{related_text}"
          end

        "#{header}\n\nDefinição:\n#{definition}#{related}"

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
      %{type: :typespec, kind: kind, module: module, name: name, arity: arity} = info ->
        kind_str =
          case kind do
            :type -> "Tipo"
            :opaque -> "Tipo opaco"
            :typep -> "Tipo privado"
            :spec -> "Especificação"
            :callback -> "Callback"
            :macrocallback -> "Macrocallback"
            _ -> "Typespec"
          end

        definition =
          case info[:definition] do
            nil -> "<p>Definição não disponível</p>"
            {:error, msg} -> "<p class=\"error\">Erro: #{escape_html(msg)}</p>"
            definition -> "<pre class=\"definition\">#{escape_html(definition)}</pre>"
          end

        related =
          case info[:related_types] do
            nil ->
              ""

            [] ->
              ""

            related ->
              """
              <div class="related-types">
                <h4>Tipos relacionados:</h4>
                <ul>
                  #{Enum.map(related, fn
                %{name: name, arity: arity, found: true, definition: def} -> "<li><code>#{name}/#{arity}</code>: <code>#{escape_html(StringUtils.truncate(def, 100))}</code></li>"
                %{name: name, arity: arity} -> "<li><code>#{name}/#{arity}</code> <span class=\"not-found\">(não encontrado)</span></li>"
              end) |> Enum.join("\n")}
                </ul>
              </div>
              """
          end

        """
        <div class="typespec-inspector">
          <h3>#{kind_str}: <code>#{inspect(module)}.#{name}/#{arity}</code></h3>

          <div class="definition-section">
            <h4>Definição:</h4>
            #{definition}
          </div>

          #{related}
        </div>
        """

      {:error, message} ->
        "<div class=\"typespec-inspector error\"><p>Erro: #{escape_html(message)}</p></div>"

      _ ->
        "<div class=\"typespec-inspector unknown\"><p>Resultado de inspeção desconhecido</p></div>"
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
