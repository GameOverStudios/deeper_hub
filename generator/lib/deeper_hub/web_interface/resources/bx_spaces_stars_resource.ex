defmodule DeeperHub.WebInterface.Resources.BxSpacesStars do
  @moduledoc """
  Recurso REST para bx_spaces_stars.
  Fornece endpoints para gerenciar bx_spaces_stars.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesStars,
    resource_name: "bx_spaces_star"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
