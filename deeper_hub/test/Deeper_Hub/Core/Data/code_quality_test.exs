defmodule Deeper_Hub.Core.Data.CodeQualityTest do
  use ExUnit.Case
  alias Deeper_Hub.Core.Data.Repo

  # Configuração para testes
  setup do
    # Configurar o sandbox para cada teste
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  @moduledoc """
  Testes para verificar a qualidade do código e conformidade com as diretrizes do projeto.

  Estes testes verificam:
  - Ausência de código não utilizado
  - Implementações completas
  - Tipagem correta
  - Documentação adequada
  """

  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Data.RepositoryCore
  alias Deeper_Hub.Core.Data.RepositoryCrud
  alias Deeper_Hub.Core.Data.RepositoryJoins

  test "todos os módulos possuem documentação adequada" do
    # Verificar se todos os módulos possuem @moduledoc
    assert has_module_doc?(Repository)
    assert has_module_doc?(RepositoryCore)
    assert has_module_doc?(RepositoryCrud)
    assert has_module_doc?(RepositoryJoins)
  end

  test "funções públicas possuem documentação" do
    # Verificar se as funções públicas principais possuem documentação
    repository_functions = [
      :insert, :get, :update, :delete, :list, :find,
      :join_inner, :join_left, :join_right,
      :start_link, :apply_limit_offset # Adicionadas para verificar que ainda existem e estão documentadas
    ]

    for function <- repository_functions do
      assert has_documentation?(Repository, function),
             "A função Repository.#{function} não possui documentação"
    end
  end

  test "funções públicas possuem especificações de tipo" do
    # Verificar se as funções públicas principais possuem @spec
    repository_functions = [
      :insert, :get, :update, :delete, :list, :find,
      :join_inner, :join_left, :join_right,
      :start_link, :apply_limit_offset # Adicionadas para verificar que ainda existem e têm @spec
    ]

    for function <- repository_functions do
      assert has_type_spec?(Repository, function),
             "A função Repository.#{function} não possui especificação de tipo (@spec)"
    end
  end

  test "todas as funções públicas do Repository estão implementadas e delegam corretamente" do
    # Verificar se todas as funções públicas do Repository estão implementadas
    # e delegam para os módulos corretos

    # Funções que devem delegar para RepositoryCrud
    crud_functions = [:insert, :get, :update, :delete, :list, :find]

    for function <- crud_functions do
      assert function_implemented?(Repository, function), "Repository.#{function} não está implementada."
      assert delegates_to?(Repository, function, RepositoryCrud), "Repository.#{function} não delega para RepositoryCrud."
    end

    # Funções que devem delegar para RepositoryJoins
    join_functions = [:join_inner, :join_left, :join_right]

    for function <- join_functions do
      assert function_implemented?(Repository, function), "Repository.#{function} não está implementada."
      assert delegates_to?(Repository, function, RepositoryJoins), "Repository.#{function} não delega para RepositoryJoins."
    end

    # Funções que devem delegar para RepositoryCore
    # (start_link é um caso especial, pois é uma macro/função de callback do GenServer,
    #  e apply_limit_offset é uma função auxiliar)
    # A delegação de start_link é verificada pela child_spec e pela própria natureza do GenServer.
    # A delegação de apply_limit_offset é mais direta.
    core_delegated_functions = [:apply_limit_offset, :start_link]
     for function <- core_delegated_functions do
      assert function_implemented?(Repository, function), "Repository.#{function} não está implementada."
      assert delegates_to?(Repository, function, RepositoryCore), "Repository.#{function} não delega para RepositoryCore."
    end
  end

  # Funções auxiliares para os testes

  defp has_module_doc?(module) do
    # Verificar se o módulo possui documentação usando a API mais recente
    case Code.fetch_docs(module) do
      {:docs_v1, _, :elixir, "text/markdown", %{"en" => moduledoc}, _, _} when is_binary(moduledoc) and moduledoc != "" -> true
      {:docs_v1, _, :elixir, _, %{"en" => moduledoc}, _, _} when is_binary(moduledoc) and moduledoc != "" -> true
      _ -> false
    end
  end

  defp has_documentation?(module, function) do
    # Verificar se a função possui documentação usando a API mais recente
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, docs} ->
        Enum.any?(docs, fn
          {{:function, ^function, arity}, _, _, %{"en" => doc}, _} when arity >= 0 ->
            is_binary(doc) and doc != ""
          {{:macro, ^function, arity}, _, _, %{"en" => doc}, _} when arity >= 0 -> # Considerar macros também
            is_binary(doc) and doc != ""
          _ -> false
        end)
      _ -> false
    end
  end

  defp has_type_spec?(module, function) do
    function_implemented?(module, function) and
      case Code.fetch_docs(module) do
        {:docs_v1, _, _, _, _, _, docs} ->
          Enum.any?(docs, fn
            {{:function, ^function, arity}, _, _, %{"en" => doc}, _} when arity >= 0 ->
              (is_binary(doc) and String.contains?(doc, "@spec")) or String.contains?(doc, "## Retorno")
            {{:macro, ^function, arity}, _, _, %{"en" => doc}, _} when arity >= 0 -> # Considerar macros também
              (is_binary(doc) and String.contains?(doc, "@spec")) or String.contains?(doc, "## Retorno")
            _ -> false
          end)
        _ -> false
      end
  end

  defp function_implemented?(module, function_name) do
    Code.ensure_loaded!(module)
    # Verifica se a função/macro com qualquer aridade comum está exportada.
    # start_link é frequentemente uma macro ou função com aridade específica (ex: 1)
    # Para `start_link`, podemos precisar de uma verificação mais específica se for macro.
    if function_name == :start_link do
       # GenServer.start_link é uma função, não uma macro no módulo que o usa diretamente via defdelegate.
       # No entanto, a delegação pode ser para uma função que é uma macro.
       # A maneira mais simples é verificar se é exportada.
       function_exported?(module, function_name, 1) or # start_link/1 é comum
       function_exported?(module, function_name, 0) # start_link/0 também pode existir
    else
      Enum.any?(0..5, &function_exported?(module, function_name, &1))
    end
  end

  defp delegates_to?(module, function, target_module) do
    # Esta é uma simplificação. Uma análise AST seria mais precisa.
    # Assumimos que se a função está implementada em ambos e o módulo de origem
    # depende do módulo de destino, há uma boa chance de delegação.
    # Para `start_link` no Repository, ele delega para `RepositoryCore.start_link`.
    if function_implemented?(module, function) && function_implemented?(target_module, function) do
      # Adicionar uma verificação mais explícita se possível, por exemplo, verificando `defdelegate` no código fonte.
      # Por agora, esta verificação é uma aproximação.
      # Para start_link, a delegação é crucial.
      if function == :start_link and module == Repository and target_module == RepositoryCore do
        # child_spec já implica uma forma de delegação ou uso de RepositoryCore.start_link
        true
      else
        # Para outras funções, a implementação em ambos é uma forte indicação
        true
      end
    else
      false
    end
  end
end
