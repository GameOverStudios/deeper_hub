defmodule DeeperHub.WebInterface.Plugs.JsonResponse do
  @moduledoc """
  Módulo utilitário para respostas JSON padronizadas.
  
  Este módulo fornece funções auxiliares para gerar respostas JSON
  consistentes em toda a aplicação.
  """
  
  import Plug.Conn
  
  @doc """
  Envia uma resposta JSON com status 200 (OK).
  
  ## Parâmetros
    * `conn` - Conexão Plug
    * `data` - Dados a serem enviados como JSON
  
  ## Retorno
    * `conn` - Conexão Plug atualizada
  """
  def json_ok(conn, data) do
    json_response(conn, 200, data)
  end
  
  @doc """
  Envia uma resposta JSON com status 201 (Created).
  
  ## Parâmetros
    * `conn` - Conexão Plug
    * `data` - Dados a serem enviados como JSON
  
  ## Retorno
    * `conn` - Conexão Plug atualizada
  """
  def json_created(conn, data) do
    json_response(conn, 201, data)
  end
  
  @doc """
  Envia uma resposta JSON com status 400 (Bad Request).
  
  ## Parâmetros
    * `conn` - Conexão Plug
    * `data` - Dados a serem enviados como JSON
  
  ## Retorno
    * `conn` - Conexão Plug atualizada
  """
  def json_bad_request(conn, data) do
    json_response(conn, 400, data)
  end
  
  @doc """
  Envia uma resposta JSON com status 401 (Unauthorized).
  
  ## Parâmetros
    * `conn` - Conexão Plug
    * `data` - Dados a serem enviados como JSON
  
  ## Retorno
    * `conn` - Conexão Plug atualizada
  """
  def json_unauthorized(conn, data) do
    json_response(conn, 401, data)
  end
  
  @doc """
  Envia uma resposta JSON com status 403 (Forbidden).
  
  ## Parâmetros
    * `conn` - Conexão Plug
    * `data` - Dados a serem enviados como JSON
  
  ## Retorno
    * `conn` - Conexão Plug atualizada
  """
  def json_forbidden(conn, data) do
    json_response(conn, 403, data)
  end
  
  @doc """
  Envia uma resposta JSON com status 404 (Not Found).
  
  ## Parâmetros
    * `conn` - Conexão Plug
    * `data` - Dados a serem enviados como JSON
  
  ## Retorno
    * `conn` - Conexão Plug atualizada
  """
  def json_not_found(conn, data) do
    json_response(conn, 404, data)
  end
  
  @doc """
  Envia uma resposta JSON com status 429 (Too Many Requests).
  
  ## Parâmetros
    * `conn` - Conexão Plug
    * `data` - Dados a serem enviados como JSON
  
  ## Retorno
    * `conn` - Conexão Plug atualizada
  """
  def json_too_many_requests(conn, data) do
    json_response(conn, 429, data)
  end
  
  @doc """
  Envia uma resposta JSON com status 500 (Internal Server Error).
  
  ## Parâmetros
    * `conn` - Conexão Plug
    * `data` - Dados a serem enviados como JSON
  
  ## Retorno
    * `conn` - Conexão Plug atualizada
  """
  def json_server_error(conn, data) do
    json_response(conn, 500, data)
  end
  
  @doc """
  Envia uma resposta JSON com o status especificado.
  
  ## Parâmetros
    * `conn` - Conexão Plug
    * `status` - Código de status HTTP
    * `data` - Dados a serem enviados como JSON
  
  ## Retorno
    * `conn` - Conexão Plug atualizada
  """
  def json_response(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
    |> halt()
  end
end
