defmodule DeeperHub.WebInterface.Resources.BxTimelineMetaKeywords do
  @moduledoc """
  Recurso REST para bx_timeline_meta_keywords.
  Fornece endpoints para gerenciar bx_timeline_meta_keywords.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineMetaKeywords,
    resource_name: "bx_timeline_meta_keyword"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
