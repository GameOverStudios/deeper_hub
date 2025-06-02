defmodule DeeperHub.WebInterface.Resources.BxPhotosVotes do
  @moduledoc """
  Recurso REST para bx_photos_votes.
  Fornece endpoints para gerenciar bx_photos_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPhotosVotes,
    resource_name: "bx_photos_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
