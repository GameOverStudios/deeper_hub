defmodule DeeperHub.WebInterface.Resources.BxTasksReports do
  @moduledoc """
  Recurso REST para bx_tasks_reports.
  Fornece endpoints para gerenciar bx_tasks_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksReports,
    resource_name: "bx_tasks_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
