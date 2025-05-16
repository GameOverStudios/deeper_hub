defmodule Mix.Tasks.Inspect.ToDb do
  @moduledoc """
  Tarefa Mix para inspecionar módulos Deeper_Hub e salvar no banco de dados SQLite e em arquivo de texto. 💾🔍📝

  Executa os seguintes passos:
  1. Garante que o banco de dados do inspetor exista (`ecto.create`).
  2. Aplica as migrações pendentes (`ecto.migrate`).
  3. Chama `Deeper_Hub.ModuleInspector.inspect_all_deeper_hub_modules()`.
  4. Insere/Atualiza as informações coletadas no banco de dados.
  5. Exporta as informações para um arquivo de texto (`modules_documentation.txt`).

  Uso:

      mix inspect.to_db

  """
  use Mix.Task

  alias Deeper_Hub.InspectorRepo
  alias Deeper_Hub.Inspector.{Module, Function, TypeSpec, Behaviour}
  alias Deeper_Hub.ModuleInspectorSimple, as: ModuleInspector
  import Ecto.Query

  @shortdoc "Inspeciona módulos Deeper_Hub e salva no banco de dados e em arquivo de texto."
  def run(_args) do
    # Garante que o Ecto e o Repo estejam disponíveis
    Mix.Task.run("app.start")
    ensure_repo_started()

    # 1. Setup do Banco de Dados
    setup_database()

    # 2. Inspecionar Módulos
    Mix.shell().info("🚀 Iniciando inspeção dos módulos (versão simplificada)...")
    inspection_results = ModuleInspector.inspect_all_deeper_hub_modules()

    # 3. Salvar no Banco de Dados e em Arquivo de Texto
    case inspection_results do
      {:error, :app_start_error, reason} ->
        Mix.shell().error("Falha ao iniciar a aplicação para inspeção: #{inspect(reason)}")
        exit({:shutdown, 1})

      results when is_list(results) ->
        Mix.shell().info("💾 Salvando resultados no banco de dados...")
        save_results(results)

        Mix.shell().info("📝 Exportando documentação para arquivo de texto...")
        export_to_text_file(results)

        Mix.shell().info("📝 Criando índice de módulos...")
        create_modules_index(results)

        Mix.shell().info("✅ Processo concluído!")

      _ ->
        Mix.shell().error("Resultado inesperado da inspeção: #{inspect(inspection_results)}")
        exit({:shutdown, 1})
    end
  end

  defp ensure_repo_started do
    case Process.whereis(InspectorRepo.Supervisor) do
      nil ->
        Mix.shell().info("Iniciando InspectorRepo...")
        {:ok, _pid} = InspectorRepo.start_link([])

      _pid ->
        # Já está rodando
        :ok
    end

    :ok
  rescue
    _ ->
      Mix.shell().error("Falha ao iniciar o InspectorRepo. Verifique sua configuração.")
      exit({:shutdown, 1})
  end

  defp setup_database do
    Mix.shell().info("🔧 Configurando banco de dados do inspetor...")

    # Cria o banco se não existir (-r especifica o repo)
    case Mix.Tasks.Ecto.Create.run(["-r", "Deeper_Hub.InspectorRepo", "--quiet"]) do
      :ok ->
        :ok

      # Ignora erro se DB já existe
      {:error, _} ->
        :ok

      _ ->
        Mix.shell().warn("Comando ecto.create falhou ou retornou valor inesperado.")
    end

    # Roda as migrações
    case Mix.Tasks.Ecto.Migrate.run(["-r", "Deeper_Hub.InspectorRepo", "--quiet"]) do
      :ok ->
        Mix.shell().info("Migrações aplicadas com sucesso.")

      error ->
        Mix.shell().error("Erro ao aplicar migrações: #{inspect(error)}")
        exit({:shutdown, 1})
    end
  end

  defp save_results(results) do
    # Para cada resultado de inspeção, salva no banco de dados
    results
    |> Enum.each(fn
      {:ok, result} ->
        # Salva módulo, funções, typespecs e behaviours
        try do
          save_module_info(result)
        rescue
          e ->
            Mix.shell().error("  ❌ Erro ao salvar módulo #{result.name}: #{Exception.message(e)}")
        end

      {:error, reason} ->
        Mix.shell().error("  ❌ Erro ao processar resultado: #{inspect(reason)}")
    end)
  end

  defp save_module_info(module_info) do
    # Monta os atributos para inserção em massa
    module_attrs = %{
      name: module_info.name,
      moduledoc: module_info.moduledoc || "",
      struct_definition: module_info.struct_definition || ""
    }

    # Upsert Módulo (insere ou atualiza)
    case InspectorRepo.insert(Module.changeset(%Deeper_Hub.Inspector.Module{}, module_attrs),
           on_conflict: :replace_all,
           conflict_target: :name
         ) do
      {:ok, _module_db} ->
        # Salva informações relacionadas APÓS salvar o módulo
        save_behaviours(module_info.name, module_info.behaviours || [])
        save_functions(module_info.name, module_info.functions || [])
        save_typespecs(module_info.name, module_info.typespecs || [])
        Mix.shell().info("  💾 Salvo: #{module_info.name}")

      {:error, changeset} ->
        Mix.shell().error(
          "  ❌ Erro ao salvar módulo #{module_info.name}: #{inspect(changeset.errors)}"
        )
    end
  end

  defp save_behaviours(module_name, behaviours) do
    InspectorRepo.delete_all(from b in Behaviour, where: b.module_name == ^module_name)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    behaviour_attrs_list =
      Enum.map(behaviours, fn behaviour_atom ->
        %{
          module_name: module_name,
          behaviour_module: Atom.to_string(behaviour_atom),
          inserted_at: now,
          updated_at: now
        }
      end)

    unless Enum.empty?(behaviour_attrs_list) do
      InspectorRepo.insert_all(Behaviour, behaviour_attrs_list, on_conflict: :nothing)
    end
  end

  defp save_functions(module_name, functions) do
    # DEBUG: Inspecionar a lista recebida
    IO.inspect(functions, label: "💾 Received functions for #{module_name}", limit: :infinity)

    # Deleta funções antigas
    InspectorRepo.delete_all(from f in Function, where: f.module_name == ^module_name)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    function_attrs_list =
      Enum.map(functions, fn func ->
        %{
          module_name: module_name,
          name: func.name,
          arity: func.arity,
          doc: func.doc,
          signature: func.signature,
          inserted_at: now,
          updated_at: now
        }
      end)

    unless Enum.empty?(function_attrs_list) do
      InspectorRepo.insert_all(Function, function_attrs_list, on_conflict: :nothing)
    end
  end

  defp save_typespecs(module_name, typespecs) do
    # Deleta typespecs antigos
    InspectorRepo.delete_all(from t in TypeSpec, where: t.module_name == ^module_name)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    typespec_attrs_list =
      Enum.map(typespecs, fn spec ->
        %{
          module_name: module_name,
          kind: spec.kind,
          name: spec.name,
          arity: spec.arity,
          definition: spec.definition,
          inserted_at: now,
          updated_at: now
        }
      end)

    unless Enum.empty?(typespec_attrs_list) do
      InspectorRepo.insert_all(TypeSpec, typespec_attrs_list)
    end
  end

  # Função para exportar a documentação dos módulos para um arquivo de texto
  @doc """
  Exporta a documentação dos módulos para um arquivo de texto.

  O arquivo conterá para cada módulo:
  - Nome do módulo
  - Documentação do módulo (@moduledoc)
  - Lista de funções com suas documentações (@doc)

  📝 O arquivo será salvo na raiz do projeto como `modules_documentation.txt`.
  """
  defp create_modules_index(results) do
    # Caminho do arquivo de índice
    index_path = Path.join(File.cwd!(), "modules_index.txt")

    # Extrai os nomes dos módulos sem repetição
    module_names =
      results
      |> Enum.map(fn
        {:ok, result} -> result.name
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    # Cria o conteúdo do arquivo
    index_content = Enum.join(module_names, "\n")

    # Escreve o arquivo
    File.write!(index_path, index_content)

    Mix.shell().info("  💾 Índice salvo em #{index_path} com #{length(module_names)} módulos.")
  end

  defp export_to_text_file(results) do
    # Caminho do arquivo de saída
    file_path = Path.join(File.cwd!(), "modules_documentation.txt")

    # Cria o arquivo (ou sobrescreve se já existir)
    {:ok, file} = File.open(file_path, [:write, :utf8])

    # Escreve um cabeçalho no arquivo
    IO.write(file, "# Documentação dos Módulos Deeper_Hub\n")
    IO.write(file, "Gerado em: #{DateTime.utc_now() |> DateTime.to_string()}\n\n")

    # Processa cada resultado da inspeção
    Enum.each(results, fn
      {:ok, %ModuleInspector.ModuleInfo{} = info} ->
        # Escreve informações do módulo
        IO.write(file, "## Módulo: #{info.name}\n\n")

        # Escreve a documentação do módulo se existir
        case info.moduledoc do
          nil -> IO.write(file, "*Sem documentação de módulo*\n\n")
          doc -> IO.write(file, "### Documentação do Módulo\n\n#{doc}\n\n")
        end

        # Escreve informações sobre comportamentos implementados
        unless Enum.empty?(info.behaviours) do
          behaviours_str =
            info.behaviours
            |> Enum.map(&Atom.to_string/1)
            |> Enum.join(", ")

          IO.write(file, "### Comportamentos Implementados\n\n#{behaviours_str}\n\n")
        end

        # Escreve informações sobre as funções
        IO.write(file, "### Funções\n\n")

        if Enum.empty?(info.functions) do
          IO.write(file, "*Nenhuma função documentada*\n\n")
        else
          Enum.each(info.functions, fn %ModuleInspector.FunctionInfo{} = func ->
            # Nome e aridade da função
            IO.write(file, "#### `#{func.name}/#{func.arity}`\n\n")

            # Assinatura da função se disponível
            if func.signature do
              IO.write(file, "```elixir\n#{func.signature}\n```\n\n")
            end

            # Documentação da função
            case func.doc do
              nil -> IO.write(file, "*Sem documentação*\n\n")
              doc -> IO.write(file, "#{doc}\n\n")
            end
          end)
        end

        # Adiciona um separador entre módulos
        IO.write(file, "---\n\n")

      {:error, {module, error, _stack}} ->
        # Registra erros de inspeção no arquivo
        IO.write(file, "## Erro ao inspecionar módulo: #{inspect(module)}\n\n")
        IO.write(file, "Erro: #{inspect(error)}\n\n---\n\n")

      # Ignora outros tipos de resultados
      _ ->
        :ok
    end)

    # Fecha o arquivo
    File.close(file)

    Mix.shell().info("  📄 Documentação exportada para: #{file_path}")
  end
end
