defmodule DeeperHub.WebInterface.Resources.BxFilesReports do
  @moduledoc """
  Recurso REST para bx_files_reports.
  Fornece endpoints para gerenciar bx_files_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxFilesReports,
    resource_name: "bx_files_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
