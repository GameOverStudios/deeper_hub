defmodule DeeperHub.WebInterface.Resources.BxSpacesMetaKeywords do
  @moduledoc """
  Recurso REST para bx_spaces_meta_keywords.
  Fornece endpoints para gerenciar bx_spaces_meta_keywords.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesMetaKeywords,
    resource_name: "bx_spaces_meta_keyword"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
