defmodule DeeperHub.WebInterface.Resources.BxPhotosEntries do
  @moduledoc """
  Recurso REST para bx_photos_entries.
  Fornece endpoints para gerenciar bx_photos_entries.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPhotosEntries,
    resource_name: "bx_photos_entrie"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
