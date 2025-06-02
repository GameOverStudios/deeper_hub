defmodule DeeperHub.WebInterface.Resources.BxConvosViewsTrack do
  @moduledoc """
  Recurso REST para bx_convos_views_tracks.
  Fornece endpoints para gerenciar bx_convos_views_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxConvosViewsTrack,
    resource_name: "bx_convos_views_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
