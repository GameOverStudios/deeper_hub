defmodule DeeperHub.WebInterface.Resources.BxPhotosReports do
  @moduledoc """
  Recurso REST para bx_photos_reports.
  Fornece endpoints para gerenciar bx_photos_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPhotosReports,
    resource_name: "bx_photos_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
