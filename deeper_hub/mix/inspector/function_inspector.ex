defmodule DeeperHub.Inspector.FunctionInspector do
  @moduledoc """
  Inspetor especializado em funções e seus metadados 🔍

  Este módulo implementa o comportamento InspectorBehaviour para analisar
  funções, extraindo informações como aridade, documentação, especificações de tipo,
  e outros metadados relevantes.
  """

  @behaviour DeeperHub.Inspector.Behaviours.InspectorBehaviour

  alias DeeperHub.Shared.Utils.StringUtils

  @doc """
  Inspeciona uma função e retorna informações detalhadas sobre ela 🔎

  ## Parâmetros

    * `function` - A função a ser inspecionada (como {module, function_name, arity} ou função anônima)
    * `options` - Opções para personalizar a inspeção
      * `:include_source` - Se deve incluir o código fonte (padrão: false)
      * `:include_docs` - Se deve incluir a documentação (padrão: true)
      * `:include_specs` - Se deve incluir especificações de tipo (padrão: true)

  ## Retorno

  Retorna um mapa com informações detalhadas sobre a função.

  ## Exemplos

      iex> DeeperHub.Inspector.FunctionInspector.inspect_function({Enum, :map, 2})
      %{
        type: :function,
        module: Enum,
        name: :map,
        arity: 2,
        docs: "...",
        specs: [...],
        exported: true
      }
  """
  @impl true
  def inspect_function(function, options \\ []) do
    include_source = Keyword.get(options, :include_source, false)
    include_docs = Keyword.get(options, :include_docs, true)
    include_specs = Keyword.get(options, :include_specs, true)

    case function do
      {module, function_name, arity}
      when is_atom(module) and is_atom(function_name) and is_integer(arity) ->
        inspect_mfa(module, function_name, arity, include_source, include_docs, include_specs)

      fun when is_function(fun) ->
        inspect_anonymous_function(fun, include_source)

      _ ->
        {:error, "Formato de função não suportado"}
    end
  end

  @doc """
  Verifica se o elemento é uma função ou referência a função válida ✅

  ## Parâmetros

    * `element` - O elemento a ser verificado

  ## Retorno

  Retorna `true` se o elemento for uma função ou referência a função, ou `false` caso contrário.

  ## Exemplos

      iex> DeeperHub.Inspector.FunctionInspector.supported?({Enum, :map, 2})
      true
      
      iex> DeeperHub.Inspector.FunctionInspector.supported?(fn x -> x * 2 end)
      true
      
      iex> DeeperHub.Inspector.FunctionInspector.supported?("not a function")
      false
  """
  @impl true
  def supported?(element) do
    case element do
      {module, function_name, arity}
      when is_atom(module) and is_atom(function_name) and is_integer(arity) ->
        true

      fun when is_function(fun) ->
        true

      _ ->
        false
    end
  end

  @doc """
  Retorna o tipo de elemento que este inspetor suporta 📋

  ## Retorno

  Retorna o átomo `:function`.
  """
  @impl true
  def element_type(), do: :function

  @doc """
  Extrai metadados específicos da função inspecionada 📊

  ## Parâmetros

    * `function` - A função da qual extrair metadados
    * `options` - Opções para personalizar a extração

  ## Retorno

  Retorna um mapa com metadados da função.
  """
  @impl true
  def extract_metadata(function, options \\ []) do
    case function do
      {module, function_name, arity}
      when is_atom(module) and is_atom(function_name) and is_integer(arity) ->
        %{
          module: module,
          name: function_name,
          arity: arity,
          exported: is_function_exported?(module, function_name, arity),
          type: :named_function
        }

      fun when is_function(fun) ->
        {module, name, arity} = Function.info(fun, :name)
        env = Function.info(fun, :env)

        %{
          type: :anonymous_function,
          arity: Function.info(fun, :arity),
          module: module,
          name: name,
          env: env
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

  defp inspect_mfa(module, function_name, arity, include_source, include_docs, include_specs) do
    # Verificar se a função existe
    unless is_function_exported?(module, function_name, arity) or
             (Code.ensure_loaded?(module) and
                is_function_exported?(module, function_name, arity, :private)) do
      return_error("Função #{inspect(module)}.#{function_name}/#{arity} não encontrada")
    end

    # Coletar informações básicas
    result = %{
      type: :function,
      module: module,
      name: function_name,
      arity: arity,
      exported: function_exported?(module, function_name, arity)
    }

    # Adicionar documentação se solicitado
    result =
      if include_docs do
        docs = get_function_docs(module, function_name, arity)
        Map.put(result, :docs, docs)
      else
        result
      end

    # Adicionar especificações de tipo se solicitado
    result =
      if include_specs do
        specs = get_function_specs(module, function_name, arity)
        Map.put(result, :specs, specs)
      else
        result
      end

    # Adicionar código fonte se solicitado
    result =
      if include_source do
        source = get_function_source(module, function_name, arity)
        Map.put(result, :source, source)
      else
        result
      end

    result
  end

  defp inspect_anonymous_function(fun, include_source) do
    # Obter informações básicas
    info = Function.info(fun)

    result = %{
      type: :anonymous_function,
      arity: info[:arity],
      module: info[:module],
      env: info[:env]
    }

    # Adicionar código fonte se solicitado e disponível
    result =
      if include_source do
        # Tentar obter o código fonte (nem sempre disponível para funções anônimas)
        source = get_anonymous_function_source(fun)
        Map.put(result, :source, source)
      else
        result
      end

    result
  end

  defp get_function_docs(module, function_name, arity) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, docs} ->
        # Filtrar para encontrar a documentação da função específica
        function_doc =
          Enum.find_value(docs, nil, fn
            {{:function, ^function_name, ^arity}, _, _, %{"en" => doc}, _} -> doc
            {{:function, ^function_name, ^arity}, _, _, doc, _} when is_binary(doc) -> doc
            _ -> nil
          end)

        function_doc || "Documentação não disponível"

      _ ->
        "Documentação não disponível"
    end
  end

  defp get_function_specs(module, function_name, arity) do
    # Tentar obter especificações de tipo
    # Nota: Isso requer acesso a informações de compilação que nem sempre estão disponíveis
    try do
      specs = Code.Typespec.fetch_specs(module)

      case specs do
        {:ok, all_specs} ->
          # Filtrar para a função específica
          Enum.filter(all_specs, fn {{name, ar}, _} ->
            name == function_name and ar == arity
          end)
          |> case do
            [] ->
              "Especificações de tipo não disponíveis"

            specs ->
              Enum.map(specs, fn {_, spec_ast} ->
                Macro.to_string(spec_ast)
              end)
          end

        _ ->
          "Especificações de tipo não disponíveis"
      end
    rescue
      _ -> "Erro ao obter especificações de tipo"
    end
  end

  defp get_function_source(module, function_name, arity) do
    # Tentar obter o código fonte
    # Nota: Isso só funciona se o código fonte estiver disponível
    try do
      case :code.which(module) do
        :preloaded ->
          "Código fonte não disponível (módulo pré-carregado)"

        :non_existing ->
          "Módulo não existe"

        beam_file when is_list(beam_file) ->
          # Tentar encontrar o arquivo fonte
          beam_file = List.to_string(beam_file)
          source_file = Path.rootname(beam_file) <> ".ex"

          if File.exists?(source_file) do
            # Ler o arquivo fonte e tentar encontrar a definição da função
            source = File.read!(source_file)
            # Implementação simplificada - uma análise mais robusta exigiria um parser
            pattern = ~r/def\s+#{function_name}\s*\([^)]*\)\s*do[\s\S]*?end/

            case Regex.run(pattern, source) do
              [match | _] -> match
              nil -> "Definição de função não encontrada no código fonte"
            end
          else
            "Arquivo fonte não encontrado"
          end

        _ ->
          "Código fonte não disponível"
      end
    rescue
      e -> "Erro ao obter código fonte: #{inspect(e)}"
    end
  end

  defp get_anonymous_function_source(fun) do
    # Obter informações sobre a função anônima
    info = Function.info(fun)

    # Tentar extrair alguma representação da função
    # Nota: Isso é limitado, pois funções anônimas geralmente não têm código fonte acessível
    "Função anônima definida em #{inspect(info[:module])}"
  end

  defp is_function_exported?(module, function_name, arity, visibility \\ :public) do
    case visibility do
      :public ->
        Code.ensure_loaded?(module) and Kernel.function_exported?(module, function_name, arity)

      :private ->
        # Verificar funções privadas é mais complicado e menos confiável
        Code.ensure_loaded?(module) and module.__info__(:functions)[function_name] == arity
    end
  end

  defp format_as_text(result) do
    case result do
      %{type: :function, module: module, name: name, arity: arity} = info ->
        header = "Função: #{inspect(module)}.#{name}/#{arity}"
        exported = if info[:exported], do: "Exportada: Sim", else: "Exportada: Não"

        docs =
          case info[:docs] do
            nil -> ""
            docs -> "\n\nDocumentação:\n#{StringUtils.truncate(docs, 500)}"
          end

        specs =
          case info[:specs] do
            nil ->
              ""

            "Especificações de tipo não disponíveis" ->
              "\n\nEspecificações: Não disponíveis"

            specs when is_list(specs) ->
              "\n\nEspecificações:\n#{Enum.join(specs, "\n")}"

            specs ->
              "\n\nEspecificações:\n#{specs}"
          end

        source =
          case info[:source] do
            nil -> ""
            source -> "\n\nCódigo Fonte:\n#{StringUtils.truncate(source, 1000)}"
          end

        "#{header}\n#{exported}#{docs}#{specs}#{source}"

      %{type: :anonymous_function, arity: arity} = info ->
        header = "Função Anônima com aridade #{arity}"
        module = "Definida em módulo: #{inspect(info[:module])}"

        source =
          case info[:source] do
            nil -> ""
            source -> "\n\nInformações:\n#{source}"
          end

        "#{header}\n#{module}#{source}"

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
      %{type: :function, module: module, name: name, arity: arity} = info ->
        """
        <div class="function-inspector">
          <h3>Função: #{inspect(module)}.#{name}/#{arity}</h3>
          <p><strong>Exportada:</strong> #{if info[:exported], do: "Sim", else: "Não"}</p>
          
          #{if info[:docs], do: "<div class=\"docs\"><h4>Documentação:</h4><pre>#{escape_html(info[:docs])}</pre></div>", else: ""}
          
          #{if info[:specs], do: format_specs_html(info[:specs]), else: ""}
          
          #{if info[:source], do: "<div class=\"source\"><h4>Código Fonte:</h4><pre>#{escape_html(info[:source])}</pre></div>", else: ""}
        </div>
        """

      %{type: :anonymous_function, arity: arity} = info ->
        """
        <div class="function-inspector">
          <h3>Função Anônima com aridade #{arity}</h3>
          <p><strong>Definida em módulo:</strong> #{inspect(info[:module])}</p>
          
          #{if info[:source], do: "<div class=\"source\"><h4>Informações:</h4><pre>#{escape_html(info[:source])}</pre></div>", else: ""}
        </div>
        """

      {:error, message} ->
        "<div class=\"function-inspector error\"><p>Erro: #{escape_html(message)}</p></div>"

      _ ->
        "<div class=\"function-inspector unknown\"><p>Resultado de inspeção desconhecido</p></div>"
    end
  end

  defp format_specs_html(specs) do
    case specs do
      "Especificações de tipo não disponíveis" ->
        "<p><strong>Especificações:</strong> Não disponíveis</p>"

      specs when is_list(specs) ->
        """
        <div class="specs">
          <h4>Especificações:</h4>
          <pre>#{Enum.map(specs, &escape_html/1) |> Enum.join("\n")}</pre>
        </div>
        """

      specs ->
        """
        <div class="specs">
          <h4>Especificações:</h4>
          <pre>#{escape_html(specs)}</pre>
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
