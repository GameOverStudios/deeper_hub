defmodule DeeperHub.WebInterface.Resources.BxClassesLinks do
  @moduledoc """
  Recurso REST para bx_classes_links.
  Fornece endpoints para gerenciar bx_classes_links.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesLinks,
    resource_name: "bx_classes_link"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
