defmodule DeeperHub.WebInterface.Resources.BxVideosEmbedsProviders do
  @moduledoc """
  Recurso REST para bx_videos_embeds_providers.
  Fornece endpoints para gerenciar bx_videos_embeds_providers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxVideosEmbedsProviders,
    resource_name: "bx_videos_embeds_provider"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
