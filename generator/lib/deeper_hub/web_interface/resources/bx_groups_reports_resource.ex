defmodule DeeperHub.WebInterface.Resources.BxGroupsReports do
  @moduledoc """
  Recurso REST para bx_groups_reports.
  Fornece endpoints para gerenciar bx_groups_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxGroupsReports,
    resource_name: "bx_groups_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
