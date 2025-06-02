defmodule DeeperHub.WebInterface.Resources.BxPersonsPictures do
  @moduledoc """
  Recurso REST para bx_persons_pictures.
  Fornece endpoints para gerenciar bx_persons_pictures.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPersonsPictures,
    resource_name: "bx_persons_picture"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
