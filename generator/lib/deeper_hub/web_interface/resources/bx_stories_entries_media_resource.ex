defmodule DeeperHub.WebInterface.Resources.BxStoriesEntriesMedia do
  @moduledoc """
  Recurso REST para bx_stories_entries_medias.
  Fornece endpoints para gerenciar bx_stories_entries_medias.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxStoriesEntriesMedia,
    resource_name: "bx_stories_entries_media"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
