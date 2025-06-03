defmodule DeeperHub.WebInterface.Resources.BxAdsCategoriesTypesResource do
  @moduledoc """
  Recurso REST para bx_ads_categories_types.
  Fornece endpoints para gerenciar bx_ads_categories_types.
  """

  use Plug.Router
  
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Data.Schemas.BxAdsCategoriesTypes, as: Schema
  
  @resource_name "bx_ads_categories_type"
  
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch
  
  # GET / - Lista todos os registros
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
  
  # POST /search - Busca avançada
  post "/search" do
    Logger.info("Realizando busca avançada em #{@resource_name}s", module: __MODULE__)
    
    filters = Map.get(conn.body_params, "filters", %{})
    opts = extract_query_params(conn.query_params)
    
    case Schema.search(filters, opts) do
      {:ok, %{data: records, metadata: metadata}} ->
        send_json_response(conn, 200, %{data: records, metadata: metadata})
        
      {:error, reason} ->
        Logger.error("Erro na busca avançada de #{@resource_name}s: #{inspect(reason)}", module: __MODULE__)
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
