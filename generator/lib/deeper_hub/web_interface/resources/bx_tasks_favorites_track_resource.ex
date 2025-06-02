defmodule DeeperHub.WebInterface.Resources.BxTasksFavoritesTrack do
  @moduledoc """
  Recurso REST para bx_tasks_favorites_tracks.
  Fornece endpoints para gerenciar bx_tasks_favorites_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksFavoritesTrack,
    resource_name: "bx_tasks_favorites_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
