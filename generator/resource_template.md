defmodule DeeperHub.WebInterface.Resources.{{RESOURCE_NAME}}Resource do
  @moduledoc """
  Recurso para gerenciar {{TABLE_NAME}}.
  """
  
  use Plug.Router
  import Plug.Conn
  
  alias DeeperHub.Core.Data.Schemas.{{MODULE_NAME}}
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  plug(:match)
  plug(:dispatch)
  
  # Listar todos os registros com suporte a paginação e ordenação
  get "/" do
    Logger.info("Recebida requisição para listar {{TABLE_NAME}}", module: __MODULE__)
    
    # Extrair parâmetros de paginação e ordenação da query string
    page = get_query_param(conn, "page", "1") |> String.to_integer()
    page_size = get_query_param(conn, "page_size", "20") |> String.to_integer()
    order_by = get_query_param(conn, "order_by", "id")
    order_direction = get_query_param(conn, "order_direction", "asc")
    
    opts = %{
      page: page,
      page_size: page_size,
      order_by: order_by,
      order_direction: order_direction
    }
    
    case {{MODULE_NAME}}.all(opts) do
      {:ok, %{items: items, metadata: metadata}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: items, metadata: metadata}))
        
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{erro: "Erro ao buscar registros: #{reason}"}))
    end
  end
  
  # Buscar registro por ID
  get "/:id" do
    Logger.info("Recebida requisição para buscar {{SINGULAR_NAME}} com ID: #{id}", module: __MODULE__)
    
    case {{MODULE_NAME}}.get(id) do
      {:ok, nil} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{erro: "{{SINGULAR_NAME}} não encontrado"}))
        
      {:ok, item} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: item}))
        
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{erro: "Erro ao buscar {{SINGULAR_NAME}}: #{reason}"}))
    end
  end
  
  # Criar novo registro
  post "/" do
    Logger.info("Recebida requisição para criar {{SINGULAR_NAME}}", module: __MODULE__)
    
    # Extrair dados do corpo da requisição
    attrs = conn.body_params
    
    case {{MODULE_NAME}}.create(attrs) do
      {:ok, id} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(%{data: %{id: id}, mensagem: "{{SINGULAR_NAME}} criado com sucesso"}))
        
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{erro: "Erro ao criar {{SINGULAR_NAME}}: #{reason}"}))
    end
  end
  
  # Atualizar registro existente
  put "/:id" do
    Logger.info("Recebida requisição para atualizar {{SINGULAR_NAME}} com ID: #{id}", module: __MODULE__)
    
    # Extrair dados do corpo da requisição
    attrs = conn.body_params
    
    case {{MODULE_NAME}}.update(id, attrs) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{mensagem: "{{SINGULAR_NAME}} atualizado com sucesso"}))
        
      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{erro: "{{SINGULAR_NAME}} não encontrado"}))
        
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{erro: "Erro ao atualizar {{SINGULAR_NAME}}: #{reason}"}))
    end
  end
  
  # Excluir registro
  delete "/:id" do
    Logger.info("Recebida requisição para excluir {{SINGULAR_NAME}} com ID: #{id}", module: __MODULE__)
    
    case {{MODULE_NAME}}.delete(id) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{mensagem: "{{SINGULAR_NAME}} excluído com sucesso"}))
        
      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{erro: "{{SINGULAR_NAME}} não encontrado"}))
        
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{erro: "Erro ao excluir {{SINGULAR_NAME}}: #{reason}"}))
    end
  end
  
  # Buscar registros com filtros avançados
  post "/search" do
    Logger.info("Recebida requisição para buscar {{TABLE_NAME}} com filtros", module: __MODULE__)
    
    # Extrair filtros e opções do corpo da requisição
    filters = Map.get(conn.body_params, "filters", %{})
    
    # Extrair parâmetros de paginação e ordenação
    page = Map.get(conn.body_params, "page", 1)
    page_size = Map.get(conn.body_params, "page_size", 20)
    order_by = Map.get(conn.body_params, "order_by", "id")
    order_direction = Map.get(conn.body_params, "order_direction", "asc")
    
    opts = %{
      page: page,
      page_size: page_size,
      order_by: order_by,
      order_direction: order_direction
    }
    
    case {{MODULE_NAME}}.search(filters, opts) do
      {:ok, %{items: items, metadata: metadata}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: items, metadata: metadata}))
        
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{erro: "Erro ao buscar registros: #{reason}"}))
    end
  end
  
  # Função auxiliar para extrair parâmetros da query string
  defp get_query_param(conn, param, default) do
    conn.query_params |> Map.get(param, default)
  end
  
  # Fallback para rotas não encontradas
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{erro: "Rota não encontrada"}))
  end
end
