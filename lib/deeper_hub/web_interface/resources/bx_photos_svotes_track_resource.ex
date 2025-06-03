defmodule DeeperHub.WebInterface.Resources.BxPhotosSvotesTrackResource do
  @moduledoc """
  Recurso REST para bx_photos_svotes_tracks.
  Fornece endpoints para gerenciar bx_photos_svotes_tracks.
  
  Endpoints disponíveis:
  - GET /api/{{PLURAL_NAME}} - Lista todos os registros com suporte a paginação e ordenação
  - GET /api/{{PLURAL_NAME}}/:id - Obtém um registro específico pelo ID
  - POST /api/{{PLURAL_NAME}} - Cria um novo registro
  - PUT /api/{{PLURAL_NAME}}/:id - Atualiza um registro existente
  - DELETE /api/{{PLURAL_NAME}}/:id - Remove um registro existente
  - POST /api/{{PLURAL_NAME}}/search - Busca avançada com filtros
  - POST /api/{{PLURAL_NAME}}/batch - Operações em lote (criação, atualização, remoção)
  
  Parâmetros de consulta suportados:
  - page: Número da página (padrão: 1)
  - page_size: Tamanho da página (padrão: 20)
  - order_by: Campo para ordenação (ex: "name,created_at")
  - order_direction: Direção da ordenação ("asc" ou "desc", padrão: "asc")
  - fields: Campos a serem retornados (ex: "id,name,title")
  """

  use Plug.Router
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Data.Schemas.BxPhotosSvotesTrack, as: Schema
  
  @resource_name "bx_photos_svotes_track"
  @default_page_size 20
  @max_page_size 100
  
  # Função necessária para o Plug.Router
  def init(opts), do: opts

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch
  
  # GET / - Lista todos os registros com paginação e ordenação
  get "/" do
    Logger.info("Listando #{@resource_name}s", module: __MODULE__)
    
    opts = extract_query_params(conn.query_params)
    
    case Schema.all(opts) do
      {:ok, %{data: records, metadata: metadata}} ->
        send_json_response(conn, 200, %{data: records, metadata: metadata})
        
      {:error, reason} ->
        Logger.error("Erro ao listar #{@resource_name}s: #{inspect(reason)}", module: __MODULE__)
        send_json_response(conn, 500, %{error: "Erro interno ao processar requisição"})
    end
  end
  
  # GET /:id - Obtém um registro específico
  get "/:id" do
    id = conn.params["id"]
    Logger.info("Buscando #{@resource_name} com ID: #{id}", module: __MODULE__)
    
    case Schema.get(id) do
      {:ok, record} ->
        send_json_response(conn, 200, %{data: record})
        
      {:error, :not_found} ->
        send_json_response(conn, 404, %{error: "#{@resource_name} não encontrado"})
        
      {:error, reason} ->
        Logger.error("Erro ao buscar #{@resource_name} com ID #{id}: #{inspect(reason)}", module: __MODULE__)
        send_json_response(conn, 500, %{error: "Erro interno ao processar requisição"})
    end
  end
  
  # POST / - Cria um novo registro
  post "/" do
    Logger.info("Criando novo #{@resource_name}", module: __MODULE__)
    
    case Schema.create(conn.body_params) do
      {:ok, record} ->
        send_json_response(conn, 201, %{data: record})
        
      {:error, errors} ->
        Logger.error("Erro ao criar #{@resource_name}: #{inspect(errors)}", module: __MODULE__)
        send_json_response(conn, 422, %{errors: format_errors(errors)})
    end
  end
  
  # PUT /:id - Atualiza um registro existente
  put "/:id" do
    id = conn.params["id"]
    Logger.info("Atualizando #{@resource_name} com ID: #{id}", module: __MODULE__)
    
    case Schema.update(id, conn.body_params) do
      {:ok, record} ->
        send_json_response(conn, 200, %{data: record})
        
      {:error, :not_found} ->
        send_json_response(conn, 404, %{error: "#{@resource_name} não encontrado"})
        
      {:error, errors} ->
        Logger.error("Erro ao atualizar #{@resource_name} com ID #{id}: #{inspect(errors)}", module: __MODULE__)
        send_json_response(conn, 422, %{errors: format_errors(errors)})
    end
  end
  
  # DELETE /:id - Remove um registro existente
  delete "/:id" do
    id = conn.params["id"]
    Logger.info("Removendo #{@resource_name} com ID: #{id}", module: __MODULE__)
    
    case Schema.delete(id) do
      {:ok, _record} ->
        send_json_response(conn, 204, nil)
        
      {:error, :not_found} ->
        send_json_response(conn, 404, %{error: "#{@resource_name} não encontrado"})
        
      {:error, reason} ->
        Logger.error("Erro ao remover #{@resource_name} com ID #{id}: #{inspect(reason)}", module: __MODULE__)
        send_json_response(conn, 500, %{error: "Erro interno ao processar requisição"})
    end
  end
  
  # POST /search - Busca avançada com filtros complexos
  post "/search" do
    Logger.info("Realizando busca avançada em #{@resource_name}s", module: __MODULE__)
    
    # Extrai filtros do corpo da requisição
    filters = Map.get(conn.body_params, "filters", %{})
    
    # Extrai opções de paginação e ordenação da query string
    base_opts = extract_query_params(conn.query_params)
    
    # Extrai opções adicionais do corpo da requisição
    body_opts = %{}
      |> Map.merge(Map.take(conn.body_params, ["page", "page_size", "order_by", "order_direction", "fields"]))
      |> Map.to_list()
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    
    # Combina as opções, priorizando as do corpo
    opts = Keyword.merge(base_opts, body_opts)
    
    case Schema.search(filters, opts) do
      {:ok, %{data: records, metadata: metadata}} ->
        send_json_response(conn, 200, %{data: records, metadata: metadata})
        
      {:error, reason} ->
        Logger.error("Erro na busca avançada de #{@resource_name}s: #{inspect(reason)}", module: __MODULE__)
        send_json_response(conn, 500, %{error: "Erro interno ao processar requisição"})
    end
  end
  
  # POST /batch - Operações em lote (criação, atualização, remoção)
  post "/batch" do
    Logger.info("Executando operações em lote para #{@resource_name}s", module: __MODULE__)
    
    operations = Map.get(conn.body_params, "operations", [])
    
    if !is_list(operations) || Enum.empty?(operations) do
      send_json_response(conn, 400, %{error: "Lista de operações vazia ou inválida"})
    else
      results = Enum.map(operations, fn operation ->
        op_type = Map.get(operation, "operation")
        data = Map.get(operation, "data", %{})
        id = Map.get(operation, "id")
        
        case op_type do
          "create" ->
            case Schema.create(data) do
              {:ok, record} -> %{status: "success", operation: "create", data: record}
              {:error, errors} -> %{status: "error", operation: "create", errors: format_errors(errors)}
            end
            
          "update" when not is_nil(id) ->
            case Schema.update(id, data) do
              {:ok, record} -> %{status: "success", operation: "update", id: id, data: record}
              {:error, :not_found} -> %{status: "error", operation: "update", id: id, error: "#{@resource_name} não encontrado"}
              {:error, errors} -> %{status: "error", operation: "update", id: id, errors: format_errors(errors)}
            end
            
          "delete" when not is_nil(id) ->
            case Schema.delete(id) do
              {:ok, _} -> %{status: "success", operation: "delete", id: id}
              {:error, :not_found} -> %{status: "error", operation: "delete", id: id, error: "#{@resource_name} não encontrado"}
              {:error, reason} -> %{status: "error", operation: "delete", id: id, error: inspect(reason)}
            end
            
          _ ->
            %{status: "error", operation: op_type, error: "Operação inválida ou parâmetros incompletos"}
        end
      end)
      
      success_count = Enum.count(results, fn r -> r.status == "success" end)
      error_count = length(results) - success_count
      
      send_json_response(conn, 200, %{
        results: results,
        summary: %{
          total: length(results),
          success: success_count,
          error: error_count
        }
      })
    end
  end
  
  # Função auxiliar para extrair parâmetros de paginação, ordenação e seleção de campos
  defp extract_query_params(params) do
    # Paginação
    page = case params["page"] do
      nil -> 1
      val when is_binary(val) -> 
        case Integer.parse(val) do
          {num, _} when num > 0 -> num
          _ -> 1
        end
      _ -> 1
    end
    
    page_size = case params["page_size"] do
      nil -> @default_page_size
      val when is_binary(val) -> 
        case Integer.parse(val) do
          {num, _} when num > 0 and num <= @max_page_size -> num
          {num, _} when num > @max_page_size -> @max_page_size
          _ -> @default_page_size
        end
      _ -> @default_page_size
    end
    
    # Ordenação
    order_fields = case params["order_by"] do
      nil -> nil
      val when is_binary(val) -> 
        val
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.filter(&(String.length(&1) > 0))
        |> Enum.map(&String.to_atom/1)
    end
    
    order_direction = case params["order_direction"] do
      "desc" -> :desc
      _ -> :asc
    end
    
    # Seleção de campos
    fields = case params["fields"] do
      nil -> nil
      val when is_binary(val) -> 
        val
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.filter(&(String.length(&1) > 0))
        |> Enum.map(&String.to_atom/1)
    end
    
    # Construção das opções
    opts = [page: page, page_size: page_size]
    
    opts = if order_fields && length(order_fields) > 0 do
      Keyword.merge(opts, [order_by: order_fields, order_direction: order_direction])
    else
      opts
    end
    
    opts = if fields && length(fields) > 0 do
      Keyword.merge(opts, [fields: fields])
    else
      opts
    end
    
    # Adiciona filtros adicionais se existirem
    Enum.reduce(params, opts, fn
      {"page", _}, acc -> acc
      {"page_size", _}, acc -> acc
      {"order_by", _}, acc -> acc
      {"order_direction", _}, acc -> acc
      {"fields", _}, acc -> acc
      {key, value}, acc -> Keyword.put(acc, String.to_atom(key), value)
    end)
  end
  
  # Função auxiliar para formatar erros
  defp format_errors(errors) do
    cond do
      is_map(errors) -> errors
      is_binary(errors) -> %{general: errors}
      is_atom(errors) -> %{general: Atom.to_string(errors)}
      true -> %{general: inspect(errors)}
    end
  end
  
  # Função auxiliar para enviar resposta JSON
  defp send_json_response(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, if(is_nil(body), do: "", else: Jason.encode!(body)))
  end
end
