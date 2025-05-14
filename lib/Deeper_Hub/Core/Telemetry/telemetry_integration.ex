defmodule Deeper_Hub.Core.Telemetry.TelemetryIntegration do
  @moduledoc """
  Integração de telemetria com outros módulos do DeeperHub. 🔄

  Este módulo fornece funções auxiliares para integrar telemetria
  com outros módulos do sistema, facilitando a adição de spans
  de telemetria em funções existentes.
  """

  alias Deeper_Hub.Core.Telemetry

  @doc """
  Adiciona telemetria a uma função existente.

  Esta função recebe um módulo, o nome de uma função e seus argumentos,
  e executa a função dentro de um span de telemetria.

  ## Parâmetros

  - `module`: O módulo que contém a função
  - `function`: O nome da função como atom
  - `args`: Os argumentos para a função
  - `event_name`: Nome personalizado para o evento (opcional)
  - `metadata`: Metadados adicionais para o evento (opcional)

  ## Retorno

  - O resultado da função original

  ## Exemplo

  ```elixir
  TelemetryIntegration.with_telemetry(
    Repository, :get, [User, user_id],
    "data.repository.get_user"
  )
  ```
  """
  @spec with_telemetry(module(), atom(), list(), String.t() | nil, map()) :: any()
  def with_telemetry(module, function, args, event_name \\ nil, metadata \\ %{}) do
    # Gera um nome de evento baseado no módulo e função se não for fornecido
    event = event_name || generate_event_name(module, function)

    # Prepara metadados básicos
    base_metadata = %{
      module: module,
      function: function,
      arity: length(args)
    }

    # Adiciona argumentos sanitizados aos metadados
    args_metadata = sanitize_args(args)

    # Combina todos os metadados
    all_metadata = Map.merge(base_metadata, metadata) |> Map.put(:args, args_metadata)

    # Executa a função dentro de um span de telemetria
    Telemetry.span(event, all_metadata, fn ->
      apply(module, function, args)
    end)
  end

  @doc """
  Adiciona telemetria a um bloco de código.

  Esta macro permite adicionar telemetria a um bloco de código
  de forma mais declarativa.

  ## Parâmetros

  - `event_name`: Nome do evento
  - `metadata`: Metadados adicionais para o evento (opcional)
  - `do_block`: Bloco de código a ser executado

  ## Exemplo

  ```elixir
  import TelemetryIntegration, only: [with_telemetry: 2]

  with_telemetry "auth.validate_token" do
    # ... código a ser executado ...
  end
  ```
  """
  defmacro telemetry_span(event_name, metadata \\ quote(do: %{}), do: block) do
    quote do
      Deeper_Hub.Core.Telemetry.span(unquote(event_name), unquote(metadata), fn ->
        unquote(block)
      end)
    end
  end

  @doc """
  Adiciona telemetria a um módulo inteiro.

  Esta função deve ser chamada dentro de um módulo para adicionar
  automaticamente telemetria a todas as funções públicas.

  ## Parâmetros

  - `opts`: Opções para personalizar a telemetria (opcional)
    - `:prefix`: Prefixo para os nomes de eventos
    - `:only`: Lista de funções para adicionar telemetria (por padrão, todas)
    - `:except`: Lista de funções para excluir da telemetria

  ## Exemplo

  ```elixir
  defmodule MyModule do
    use Deeper_Hub.Core.Telemetry.TelemetryIntegration,
      prefix: "my_module",
      except: [:init, :terminate]

    # ... definições de funções ...
  end
  ```
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      # Importa a macro telemetry_span
      import Deeper_Hub.Core.Telemetry.TelemetryIntegration, only: [telemetry_span: 2, telemetry_span: 3]

      # Obtém opções
      prefix = Keyword.get(opts, :prefix, nil)
      only_functions = Keyword.get(opts, :only, nil)
      except_functions = Keyword.get(opts, :except, [])

      # Adiciona hook para adicionar telemetria após a compilação do módulo
      @before_compile {Deeper_Hub.Core.Telemetry.TelemetryIntegration, :add_telemetry}

      # Armazena opções para uso no hook
      Module.register_attribute(__MODULE__, :telemetry_opts, accumulate: false)
      Module.put_attribute(__MODULE__, :telemetry_opts, %{
        prefix: prefix,
        only: only_functions,
        except: except_functions
      })
    end
  end

  @doc false
  defmacro add_telemetry(env) do
    module = env.module
    opts = Module.get_attribute(module, :telemetry_opts)

    # Obtém todas as funções públicas do módulo
    functions = module.__info__(:functions)

    # Filtra funções com base nas opções
    functions_to_instrument = case {opts.only, opts.except} do
      {nil, except} ->
        Enum.reject(functions, fn {name, _arity} -> name in except end)

      {only, _} ->
        Enum.filter(functions, fn {name, _arity} -> name in only end)
    end

    # Gera código para adicionar telemetria a cada função
    function_overrides = for {name, arity} <- functions_to_instrument do
      args = Macro.generate_arguments(arity, module)

      quote do
        # Define uma função com o mesmo nome que chama a original com telemetria
        def unquote(name)(unquote_splicing(args)) do
          event_name = unquote(generate_event_name_from_opts(module, name, opts.prefix))

          Deeper_Hub.Core.Telemetry.span(event_name, %{
            module: unquote(module),
            function: unquote(name),
            arity: unquote(arity)
          }, fn ->
            super(unquote_splicing(args))
          end)
        end
      end
    end

    # Retorna o código gerado
    quote do
      unquote_splicing(function_overrides)
    end
  end

  # Funções privadas

  # Gera um nome de evento baseado no módulo e função
  defp generate_event_name(module, function) do
    module_name = module
                  |> Atom.to_string()
                  |> String.replace("Elixir.", "")
                  |> String.replace(".", "_")
                  |> String.downcase()

    function_name = function
                    |> Atom.to_string()
                    |> String.downcase()

    "#{module_name}.#{function_name}"
  end

  # Gera um nome de evento baseado no módulo, função e prefixo opcional
  defp generate_event_name_from_opts(module, function, prefix) do
    if prefix do
      "#{prefix}.#{function}"
    else
      generate_event_name(module, function)
    end
  end

  # Sanitiza argumentos para evitar dados sensíveis ou muito grandes
  defp sanitize_args(args) do
    Enum.map(args, &sanitize_arg/1)
  end

  # Sanitiza um único argumento
  defp sanitize_arg(arg) do
    cond do
      # Para schemas Ecto, retorna apenas o módulo e ID
      is_struct(arg) && Map.has_key?(arg, :__struct__) && Map.has_key?(arg, :id) ->
        %{
          type: "struct",
          module: arg.__struct__,
          id: Map.get(arg, :id)
        }

      # Para mapas, sanitiza valores sensíveis
      is_map(arg) ->
        sanitize_map(arg)

      # Para listas grandes, trunca
      is_list(arg) && length(arg) > 10 ->
        "[lista com #{length(arg)} itens]"

      # Para binários grandes, trunca
      is_binary(arg) && byte_size(arg) > 100 ->
        "[binário com #{byte_size(arg)} bytes]"

      # Para outros tipos, retorna como está
      true ->
        arg
    end
  end

  # Sanitiza um mapa para remover dados sensíveis
  defp sanitize_map(map) do
    sensitive_keys = [:password, :token, :secret, :api_key, :private_key, :credit_card]

    Enum.reduce(sensitive_keys, map, fn key, acc ->
      if Map.has_key?(acc, key) do
        Map.put(acc, key, "[REDACTED]")
      else
        acc
      end
    end)
  end
end
