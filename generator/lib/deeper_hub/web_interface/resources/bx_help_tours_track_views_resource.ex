defmodule DeeperHub.WebInterface.Resources.BxHelpToursTrackViews do
  @moduledoc """
  Recurso REST para bx_help_tours_track_views.
  Fornece endpoints para gerenciar bx_help_tours_track_views.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxHelpToursTrackViews,
    resource_name: "bx_help_tours_track_view"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
