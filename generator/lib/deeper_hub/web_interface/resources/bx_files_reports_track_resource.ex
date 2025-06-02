defmodule DeeperHub.WebInterface.Resources.BxFilesReportsTrack do
  @moduledoc """
  Recurso REST para bx_files_reports_tracks.
  Fornece endpoints para gerenciar bx_files_reports_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxFilesReportsTrack,
    resource_name: "bx_files_reports_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
