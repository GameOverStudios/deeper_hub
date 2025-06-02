defmodule DeeperHub.WebInterface.Resources.BxTasksReportsTrack do
  @moduledoc """
  Recurso REST para bx_tasks_reports_tracks.
  Fornece endpoints para gerenciar bx_tasks_reports_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksReportsTrack,
    resource_name: "bx_tasks_reports_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
