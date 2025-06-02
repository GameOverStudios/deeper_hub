defmodule DeeperHub.WebInterface.ResourceBase do
  @moduledoc """
  Módulo base para resources que fornece funcionalidades comuns para todos os resources.
  Implementa endpoints REST padrão e tratamento de requisições/respostas.
  """

  defmacro __using__(opts) do
    quote do
      use Plug.Router
      
      alias DeeperHub.Core.Logger
      require DeeperHub.Core.Logger
      
      @schema_module unquote(opts[:schema] || raise "É necessário fornecer :schema")
      @resource_name unquote(opts[:resource_name] || raise "É necessário fornecer :resource_name")
      
      plug :match
      plug Plug.Parsers, parsers: [:json], json_decoder: Jason
      plug :dispatch
      
      @doc """
      Endpoint GET / - Lista todos os registros com suporte a paginação e ordenação.
      
      Parâmetros de query:
        * page - Número da página (padrão: 1)
        * page_size - Tamanho da página (padrão: 20)
        * order_by - Campo para ordenação
        * order_direction - Direção da ordenação (asc ou desc)
      """
      get "/" do
        Logger.info("Listando #{@resource_name}", module: __MODULE__)
        
        # Extrair parâmetros de paginação e ordenação
        opts = extract_query_params(conn.query_params)
        
        case @schema_module.all(opts) do
          {:ok, %{data: records, metadata: metadata}} ->
            send_json_response(conn, 200, %{
              data: records,
              metadata: metadata
            })
            
          {:error, reason} ->
            Logger.error("Erro ao listar #{@resource_name}: #{inspect(reason)}", module: __MODULE__)
            send_json_response(conn, 500, %{error: "Erro interno ao processar requisição"})
        end
      end
      
      @doc """
      Endpoint GET /:id - Obtém um registro específico pelo ID.
      """
      get "/:id" do
        id = conn.params["id"]
        Logger.info("Buscando #{@resource_name} com ID: #{id}", module: __MODULE__)
        
        case @schema_module.get(id) do
          {:ok, record} ->
            send_json_response(conn, 200, %{data: record})
            
          {:error, :not_found} ->
            send_json_response(conn, 404, %{error: "#{@resource_name} não encontrado"})
            
          {:error, reason} ->
            Logger.error("Erro ao buscar #{@resource_name} com ID #{id}: #{inspect(reason)}", module: __MODULE__)
            send_json_response(conn, 500, %{error: "Erro interno ao processar requisição"})
        end
      end
      
      @doc """
      Endpoint POST / - Cria um novo registro.
      """
      post "/" do
        Logger.info("Criando novo #{@resource_name}", module: __MODULE__)
        
        case @schema_module.create(conn.body_params) do
          {:ok, record} ->
            send_json_response(conn, 201, %{data: record})
            
          {:error, %Ecto.Changeset{} = changeset} ->
            errors = format_changeset_errors(changeset)
            send_json_response(conn, 422, %{errors: errors})
            
          {:error, reason} ->
            Logger.error("Erro ao criar #{@resource_name}: #{inspect(reason)}", module: __MODULE__)
            send_json_response(conn, 500, %{error: "Erro interno ao processar requisição"})
        end
      end
      
      @doc """
      Endpoint PUT /:id - Atualiza um registro existente.
      """
      put "/:id" do
        id = conn.params["id"]
        Logger.info("Atualizando #{@resource_name} com ID: #{id}", module: __MODULE__)
        
        case @schema_module.update(id, conn.body_params) do
          {:ok, record} ->
            send_json_response(conn, 200, %{data: record})
            
          {:error, :not_found} ->
            send_json_response(conn, 404, %{error: "#{@resource_name} não encontrado"})
            
          {:error, %Ecto.Changeset{} = changeset} ->
            errors = format_changeset_errors(changeset)
            send_json_response(conn, 422, %{errors: errors})
            
          {:error, reason} ->
            Logger.error("Erro ao atualizar #{@resource_name} com ID #{id}: #{inspect(reason)}", module: __MODULE__)
            send_json_response(conn, 500, %{error: "Erro interno ao processar requisição"})
        end
      end
      
      @doc """
      Endpoint DELETE /:id - Remove um registro existente.
      """
      delete "/:id" do
        id = conn.params["id"]
        Logger.info("Removendo #{@resource_name} com ID: #{id}", module: __MODULE__)
        
        case @schema_module.delete(id) do
          {:ok, _record} ->
            send_json_response(conn, 204, nil)
            
          {:error, :not_found} ->
            send_json_response(conn, 404, %{error: "#{@resource_name} não encontrado"})
            
          {:error, reason} ->
            Logger.error("Erro ao remover #{@resource_name} com ID #{id}: #{inspect(reason)}", module: __MODULE__)
            send_json_response(conn, 500, %{error: "Erro interno ao processar requisição"})
        end
      end
      
      @doc """
      Endpoint POST /search - Busca avançada com múltiplos filtros.
      """
      post "/search" do
        Logger.info("Realizando busca avançada em #{@resource_name}", module: __MODULE__)
        
        filters = Map.get(conn.body_params, "filters", %{})
        opts = extract_query_params(conn.query_params)
        
        case @schema_module.search(filters, opts) do
          {:ok, %{data: records, metadata: metadata}} ->
            send_json_response(conn, 200, %{
              data: records,
              metadata: metadata
            })
            
          {:error, reason} ->
            Logger.error("Erro na busca avançada de #{@resource_name}: #{inspect(reason)}", module: __MODULE__)
            send_json_response(conn, 500, %{error: "Erro interno ao processar requisição"})
        end
      end
      
      # Função auxiliar para extrair parâmetros de paginação e ordenação
      defp extract_query_params(params) do
        page = case params["page"] do
          nil -> 1
          val -> String.to_integer(val)
        end
        
        page_size = case params["page_size"] do
          nil -> 20
          val -> String.to_integer(val)
        end
        
        order_by = case params["order_by"] do
          nil -> nil
          val -> String.to_atom(val)
        end
        
        order_direction = case params["order_direction"] do
          "desc" -> :desc
          _ -> :asc
        end
        
        opts = [page: page, page_size: page_size]
        
        if order_by do
          Keyword.merge(opts, [order_by: order_by, order_direction: order_direction])
        else
          opts
        end
      end
      
      # Função auxiliar para formatar erros de changeset
      defp format_changeset_errors(changeset) do
        Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Enum.reduce(opts, msg, fn {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
          end)
        end)
      end
      
      # Função auxiliar para enviar resposta JSON
      defp send_json_response(conn, status, body) do
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(status, if(is_nil(body), do: "", else: Jason.encode!(body)))
      end
      
      # Permitir que os módulos que usam esta base possam adicionar rotas personalizadas
      defoverridable [match: 2, dispatch: 2]
    end
  end
end
