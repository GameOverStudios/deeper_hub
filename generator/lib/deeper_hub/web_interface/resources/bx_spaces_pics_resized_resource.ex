defmodule DeeperHub.WebInterface.Resources.BxSpacesPicsResized do
  @moduledoc """
  Recurso REST para bx_spaces_pics_resizeds.
  Fornece endpoints para gerenciar bx_spaces_pics_resizeds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesPicsResized,
    resource_name: "bx_spaces_pics_resized"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
