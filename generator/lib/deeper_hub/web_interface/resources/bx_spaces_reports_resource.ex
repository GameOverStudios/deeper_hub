defmodule DeeperHub.WebInterface.Resources.BxSpacesReports do
  @moduledoc """
  Recurso REST para bx_spaces_reports.
  Fornece endpoints para gerenciar bx_spaces_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesReports,
    resource_name: "bx_spaces_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
