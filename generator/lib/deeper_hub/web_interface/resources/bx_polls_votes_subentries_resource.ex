defmodule DeeperHub.WebInterface.Resources.BxPollsVotesSubentries do
  @moduledoc """
  Recurso REST para bx_polls_votes_subentries.
  Fornece endpoints para gerenciar bx_polls_votes_subentries.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPollsVotesSubentries,
    resource_name: "bx_polls_votes_subentrie"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
