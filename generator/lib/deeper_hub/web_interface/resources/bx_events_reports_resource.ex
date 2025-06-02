defmodule DeeperHub.WebInterface.Resources.BxEventsReports do
  @moduledoc """
  Recurso REST para bx_events_reports.
  Fornece endpoints para gerenciar bx_events_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsReports,
    resource_name: "bx_events_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
