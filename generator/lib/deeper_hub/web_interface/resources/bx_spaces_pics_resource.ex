defmodule DeeperHub.WebInterface.Resources.BxSpacesPics do
  @moduledoc """
  Recurso REST para bx_spaces_pics.
  Fornece endpoints para gerenciar bx_spaces_pics.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesPics,
    resource_name: "bx_spaces_pic"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
