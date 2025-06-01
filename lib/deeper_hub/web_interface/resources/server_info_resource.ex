defmodule DeeperHub.WebInterface.Resources.ServerInfoResource do
  @moduledoc """
  Recurso que fornece informações detalhadas sobre o servidor.
  Este módulo é responsável por retornar dados técnicos sobre o ambiente
  de execução e configurações do sistema.
  """
  use Plug.Router
  plug :match
  plug :dispatch
  
  get "/" do
    # Informações detalhadas do servidor
    server_info = %{
      sistema: %{
        nome: "DeeperHub",
        erlang_version: :erlang.system_info(:otp_release) |> List.to_string(),
        process_count: :erlang.system_info(:process_count),
        memoria_total: :erlang.memory(:total),
        process_limit: :erlang.system_info(:process_limit)
      },
      aplicacoes: listar_aplicacoes(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(server_info))
  end
  
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{erro: "Recurso não encontrado"}))
  end
  
  # Funções privadas auxiliares
  defp listar_aplicacoes do
    # Lista as principais aplicações em execução
    [:deeper_hub, :plug, :cowboy, :jason]
    |> Enum.map(fn app ->
      # Verifica se podemos obter as especificações da aplicação
      versao = Application.spec(app, :vsn)
      
      case versao do
        nil -> 
          %{
            nome: app,
            status: "não_carregado"
          }
        _ -> 
          %{
            nome: app,
            versao: versao |> to_string(),
            status: "em_execução"
          }
      end
    end)
  end
end
