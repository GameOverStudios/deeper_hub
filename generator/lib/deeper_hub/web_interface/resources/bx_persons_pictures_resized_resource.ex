defmodule DeeperHub.WebInterface.Resources.BxPersonsPicturesResized do
  @moduledoc """
  Recurso REST para bx_persons_pictures_resizeds.
  Fornece endpoints para gerenciar bx_persons_pictures_resizeds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPersonsPicturesResized,
    resource_name: "bx_persons_pictures_resized"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
