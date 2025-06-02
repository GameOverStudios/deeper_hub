defmodule DeeperHub.WebInterface.Resources.BxTimelineEfPhotos do
  @moduledoc """
  Recurso REST para bx_timeline_ef_photos.
  Fornece endpoints para gerenciar bx_timeline_ef_photos.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineEfPhotos,
    resource_name: "bx_timeline_ef_photo"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
