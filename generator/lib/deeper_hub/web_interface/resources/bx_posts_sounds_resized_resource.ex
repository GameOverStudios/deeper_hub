defmodule DeeperHub.WebInterface.Resources.BxPostsSoundsResized do
  @moduledoc """
  Recurso REST para bx_posts_sounds_resizeds.
  Fornece endpoints para gerenciar bx_posts_sounds_resizeds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPostsSoundsResized,
    resource_name: "bx_posts_sounds_resized"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
