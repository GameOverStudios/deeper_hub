defmodule DeeperHub.WebInterface.Resources.BxVideosMetaKeywords do
  @moduledoc """
  Recurso REST para bx_videos_meta_keywords.
  Fornece endpoints para gerenciar bx_videos_meta_keywords.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxVideosMetaKeywords,
    resource_name: "bx_videos_meta_keyword"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
