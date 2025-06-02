defmodule DeeperHub.WebInterface.Resources.BxOrganizationsReports do
  @moduledoc """
  Recurso REST para bx_organizations_reports.
  Fornece endpoints para gerenciar bx_organizations_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxOrganizationsReports,
    resource_name: "bx_organizations_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
