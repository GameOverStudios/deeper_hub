defmodule DeeperHub.WebInterface.Resources.BxMarketReports do
  @moduledoc """
  Recurso REST para bx_market_reports.
  Fornece endpoints para gerenciar bx_market_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketReports,
    resource_name: "bx_market_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
