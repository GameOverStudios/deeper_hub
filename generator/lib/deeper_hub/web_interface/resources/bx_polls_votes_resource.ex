defmodule DeeperHub.WebInterface.Resources.BxPollsVotes do
  @moduledoc """
  Recurso REST para bx_polls_votes.
  Fornece endpoints para gerenciar bx_polls_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPollsVotes,
    resource_name: "bx_polls_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
