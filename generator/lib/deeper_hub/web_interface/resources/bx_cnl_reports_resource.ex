defmodule DeeperHub.WebInterface.Resources.BxCnlReports do
  @moduledoc """
  Recurso REST para bx_cnl_reports.
  Fornece endpoints para gerenciar bx_cnl_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCnlReports,
    resource_name: "bx_cnl_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
