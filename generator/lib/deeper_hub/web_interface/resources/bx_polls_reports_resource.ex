defmodule DeeperHub.WebInterface.Resources.BxPollsReports do
  @moduledoc """
  Recurso REST para bx_polls_reports.
  Fornece endpoints para gerenciar bx_polls_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPollsReports,
    resource_name: "bx_polls_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
