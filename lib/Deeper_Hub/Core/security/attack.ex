defmodule DeeperHub.Core.Security.Attack do
  @moduledoc """
  Configuração do PlugAttack para proteção contra ataques.
  
  Este módulo define regras para proteção contra ataques de força bruta,
  limitação de taxa de requisições e bloqueio de IPs maliciosos.
  """
  
  use PlugAttack
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  # Armazenamento para contadores de requisições
  # Usa ETS para armazenamento em memória
  @storage PlugAttack.Storage.Ets
  
  # Configuração global
  @rate_limit_scale 60_000  # Escala de tempo em milissegundos (1 minuto)
  @max_requests_per_minute 300  # Máximo de requisições por minuto para endpoints normais
  @max_auth_requests_per_minute 10  # Máximo de requisições de autenticação por minuto
  
  # Função para obter o endereço IP real do cliente
  # Considera headers como X-Forwarded-For para casos com proxy/load balancer
  defp get_client_ip(conn) do
    # Tenta obter o IP do header X-Forwarded-For primeiro (para casos com proxy)
    forwarded_for = Plug.Conn.get_req_header(conn, "x-forwarded-for")
    
    cond do
      # Se tiver X-Forwarded-For, usa o primeiro IP (mais à esquerda)
      length(forwarded_for) > 0 ->
        forwarded_for
        |> hd()
        |> String.split(",")
        |> hd()
        |> String.trim()
        
      # Caso contrário, usa o IP remoto da conexão
      true ->
        to_string(conn.remote_ip)
    end
  end
  
  # Função para verificar se a requisição é para autenticação
  defp auth_request?(conn) do
    conn.method == "POST" and String.match?(conn.request_path, ~r{^/api/auth/})
  end
  
  # Função para verificar se a requisição é para API
  defp api_request?(conn) do
    String.match?(conn.request_path, ~r{^/api/})
  end
  
  # Função para verificar se a requisição é para WebSocket
  defp websocket_request?(conn) do
    String.match?(conn.request_path, ~r{^/ws})
  end
  
  # Proteção contra ataques de força bruta em endpoints de autenticação
  rule "authentication_throttle", conn do
    if auth_request?(conn) do
      # Obtém o IP do cliente como chave para limitação
      key = "auth:#{get_client_ip(conn)}"
      
      # Verifica se excedeu o limite
      case check_rate(key, @max_auth_requests_per_minute, @rate_limit_scale) do
        {:allow, _} -> conn
        {:block, data} -> 
          Logger.warn("Limite de taxa excedido para autenticação por #{get_client_ip(conn)}", module: __MODULE__)
          throttle_response(conn, {key, @max_auth_requests_per_minute, data})
      end
    end
  end
  
  # Limitação de taxa para requisições de API
  rule "api_throttle", conn do
    if api_request?(conn) do
      # Obtém o IP do cliente como chave para limitação
      key = "api:#{get_client_ip(conn)}"
      
      # Verifica se excedeu o limite
      case check_rate(key, @max_requests_per_minute, @rate_limit_scale) do
        {:allow, _} -> conn
        {:block, data} -> 
          Logger.warn("Limite de taxa excedido para API por #{get_client_ip(conn)}", module: __MODULE__)
          throttle_response(conn, {key, @max_requests_per_minute, data})
      end
    end
  end
  
  # Limitação de taxa para requisições de WebSocket
  rule "websocket_throttle", conn do
    if websocket_request?(conn) do
      # Obtém o IP do cliente como chave para limitação
      key = "ws:#{get_client_ip(conn)}"
      
      # Verifica se excedeu o limite
      case check_rate(key, @max_requests_per_minute, @rate_limit_scale) do
        {:allow, _} -> conn
        {:block, data} -> 
          Logger.warn("Limite de taxa excedido para WebSocket por #{get_client_ip(conn)}", module: __MODULE__)
          throttle_response(conn, {key, @max_requests_per_minute, data})
      end
    end
  end
  
  # Bloqueio de IPs conhecidos por serem maliciosos
  rule "ip_blocklist", conn do
    # Obtém o IP do cliente
    ip = get_client_ip(conn)
    
    # Lista de IPs bloqueados - em produção, isso pode vir de um banco de dados ou arquivo
    blocked_ips = Application.get_env(:deeper_hub, :security, [])[:blocked_ips] || []
    
    # Bloqueia se o IP estiver na lista
    if Enum.member?(blocked_ips, ip) do
      block conn
    end
  end
  
  # Configuração do armazenamento para throttling
  def storage_setup do
    @storage.init({:deeper_hub_attack_storage, :ets_options})
  end
  
  # Verifica se a taxa de requisições excedeu o limite
  defp check_rate(key, limit, scale) do
    # Incrementa o contador para a chave
    count = @storage.increment({:deeper_hub_attack_storage, :ets_options}, key, 1, scale)
    
    # Verifica se excedeu o limite
    if count <= limit do
      {:allow, count}
    else
      {:block, count}
    end
  end
  
  # Resposta para requisições bloqueadas por throttling
  def throttle_response(conn, data) do
    # Obtém informações sobre o limite excedido
    {key, limit, _} = data
    
    # Extrai o tipo de regra da chave (auth, api, ws)
    rule_type = String.split(key, ":") |> hd()
    
    Logger.warn("Limite de taxa excedido: #{rule_type} por #{get_client_ip(conn)}", module: __MODULE__)
    
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.put_resp_header("retry-after", "#{div(@rate_limit_scale, 1000)}")
    |> Plug.Conn.send_resp(429, Jason.encode!(%{
      error: "Muitas requisições",
      code: "rate_limit_exceeded",
      limit: limit,
      period_seconds: div(@rate_limit_scale, 1000)
    }))
    |> Plug.Conn.halt()
  end
  
  # Resposta para requisições bloqueadas por IP
  def block_response(conn) do
    Logger.warn("IP bloqueado tentando acessar: #{get_client_ip(conn)}", module: __MODULE__)
    
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(403, Jason.encode!(%{
      error: "Acesso bloqueado",
      code: "ip_blocked"
    }))
    |> Plug.Conn.halt()
  end
end
