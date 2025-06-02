defmodule DeeperHub.WebInterface.Resources.BxClassesCovers do
  @moduledoc """
  Recurso REST para bx_classes_covers.
  Fornece endpoints para gerenciar bx_classes_covers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesCovers,
    resource_name: "bx_classes_cover"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
