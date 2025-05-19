defmodule DeeperHub.WebInterface.Controllers.JsonResponse do
  @moduledoc """
  Módulo auxiliar para gerar respostas JSON em controladores.
  
  Este módulo fornece funções para facilitar a geração de respostas JSON
  padronizadas nos controladores da aplicação.
  """
  
  import Plug.Conn
  
  @doc """
  Envia uma resposta JSON com o status 200 (OK).
  
  ## Parâmetros
    * `conn` - A conexão Plug
    * `data` - Os dados a serem enviados como JSON
  
  ## Retorno
    * A conexão Plug modificada
  """
  def json_ok(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(data))
  end
  
  @doc """
  Envia uma resposta JSON com o status 201 (Created).
  
  ## Parâmetros
    * `conn` - A conexão Plug
    * `data` - Os dados a serem enviados como JSON
  
  ## Retorno
    * A conexão Plug modificada
  """
  def json_created(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(201, Jason.encode!(data))
  end
  
  @doc """
  Envia uma resposta JSON com o status 400 (Bad Request).
  
  ## Parâmetros
    * `conn` - A conexão Plug
    * `data` - Os dados a serem enviados como JSON
  
  ## Retorno
    * A conexão Plug modificada
  """
  def json_bad_request(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(data))
  end
  
  @doc """
  Envia uma resposta JSON com o status 401 (Unauthorized).
  
  ## Parâmetros
    * `conn` - A conexão Plug
    * `data` - Os dados a serem enviados como JSON
  
  ## Retorno
    * A conexão Plug modificada
  """
  def json_unauthorized(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(data))
  end
  
  @doc """
  Envia uma resposta JSON com o status 403 (Forbidden).
  
  ## Parâmetros
    * `conn` - A conexão Plug
    * `data` - Os dados a serem enviados como JSON
  
  ## Retorno
    * A conexão Plug modificada
  """
  def json_forbidden(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(403, Jason.encode!(data))
  end
  
  @doc """
  Envia uma resposta JSON com o status 404 (Not Found).
  
  ## Parâmetros
    * `conn` - A conexão Plug
    * `data` - Os dados a serem enviados como JSON
  
  ## Retorno
    * A conexão Plug modificada
  """
  def json_not_found(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(data))
  end
  
  @doc """
  Envia uma resposta JSON com o status 429 (Too Many Requests).
  
  ## Parâmetros
    * `conn` - A conexão Plug
    * `data` - Os dados a serem enviados como JSON
    * `retry_after` - Valor opcional para o cabeçalho Retry-After
  
  ## Retorno
    * A conexão Plug modificada
  """
  def json_too_many_requests(conn, data, retry_after \\ nil) do
    conn = put_resp_content_type(conn, "application/json")
    
    conn = if retry_after do
      put_resp_header(conn, "retry-after", "#{retry_after}")
    else
      conn
    end
    
    send_resp(conn, 429, Jason.encode!(data))
  end
  
  @doc """
  Envia uma resposta JSON com o status 500 (Internal Server Error).
  
  ## Parâmetros
    * `conn` - A conexão Plug
    * `data` - Os dados a serem enviados como JSON
  
  ## Retorno
    * A conexão Plug modificada
  """
  def json_server_error(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(500, Jason.encode!(data))
  end
  
  @doc """
  Envia uma resposta JSON com o status personalizado.
  
  ## Parâmetros
    * `conn` - A conexão Plug
    * `status` - O código de status HTTP
    * `data` - Os dados a serem enviados como JSON
  
  ## Retorno
    * A conexão Plug modificada
  """
  def json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end
