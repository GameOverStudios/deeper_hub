defmodule DeeperHub.WebInterface.Resources.BxClassesReports do
  @moduledoc """
  Recurso REST para bx_classes_reports.
  Fornece endpoints para gerenciar bx_classes_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesReports,
    resource_name: "bx_classes_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
