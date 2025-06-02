defmodule DeeperHub.WebInterface.Resources.BxAlbumsVotes do
  @moduledoc """
  Recurso REST para bx_albums_votes.
  Fornece endpoints para gerenciar bx_albums_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAlbumsVotes,
    resource_name: "bx_albums_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
