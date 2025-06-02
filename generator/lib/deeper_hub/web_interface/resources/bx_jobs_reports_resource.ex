defmodule DeeperHub.WebInterface.Resources.BxJobsReports do
  @moduledoc """
  Recurso REST para bx_jobs_reports.
  Fornece endpoints para gerenciar bx_jobs_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxJobsReports,
    resource_name: "bx_jobs_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
