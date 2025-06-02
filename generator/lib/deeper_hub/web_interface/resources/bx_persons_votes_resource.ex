defmodule DeeperHub.WebInterface.Resources.BxPersonsVotes do
  @moduledoc """
  Recurso REST para bx_persons_votes.
  Fornece endpoints para gerenciar bx_persons_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPersonsVotes,
    resource_name: "bx_persons_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
