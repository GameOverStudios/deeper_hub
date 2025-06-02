defmodule DeeperHub.WebInterface.Resources.BxAlbumsReports do
  @moduledoc """
  Recurso REST para bx_albums_reports.
  Fornece endpoints para gerenciar bx_albums_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAlbumsReports,
    resource_name: "bx_albums_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
