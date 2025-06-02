defmodule DeeperHub.WebInterface.Resources.BxPhotosMetaKeywords do
  @moduledoc """
  Recurso REST para bx_photos_meta_keywords.
  Fornece endpoints para gerenciar bx_photos_meta_keywords.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPhotosMetaKeywords,
    resource_name: "bx_photos_meta_keyword"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
