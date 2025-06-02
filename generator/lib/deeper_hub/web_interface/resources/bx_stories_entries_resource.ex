defmodule DeeperHub.WebInterface.Resources.BxStoriesEntries do
  @moduledoc """
  Recurso REST para bx_stories_entries.
  Fornece endpoints para gerenciar bx_stories_entries.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxStoriesEntries,
    resource_name: "bx_stories_entrie"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
