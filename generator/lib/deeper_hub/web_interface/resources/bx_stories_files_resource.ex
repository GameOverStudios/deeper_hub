defmodule DeeperHub.WebInterface.Resources.BxStoriesFiles do
  @moduledoc """
  Recurso REST para bx_stories_files.
  Fornece endpoints para gerenciar bx_stories_files.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxStoriesFiles,
    resource_name: "bx_stories_file"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
