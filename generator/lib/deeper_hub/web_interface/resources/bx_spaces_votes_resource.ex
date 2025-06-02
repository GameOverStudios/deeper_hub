defmodule DeeperHub.WebInterface.Resources.BxSpacesVotes do
  @moduledoc """
  Recurso REST para bx_spaces_votes.
  Fornece endpoints para gerenciar bx_spaces_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesVotes,
    resource_name: "bx_spaces_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
