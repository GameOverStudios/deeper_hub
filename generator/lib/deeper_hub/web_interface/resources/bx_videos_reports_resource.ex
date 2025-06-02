defmodule DeeperHub.WebInterface.Resources.BxVideosReports do
  @moduledoc """
  Recurso REST para bx_videos_reports.
  Fornece endpoints para gerenciar bx_videos_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxVideosReports,
    resource_name: "bx_videos_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
