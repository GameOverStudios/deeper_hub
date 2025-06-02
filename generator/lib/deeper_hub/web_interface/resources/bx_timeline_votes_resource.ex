defmodule DeeperHub.WebInterface.Resources.BxTimelineVotes do
  @moduledoc """
  Recurso REST para bx_timeline_votes.
  Fornece endpoints para gerenciar bx_timeline_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineVotes,
    resource_name: "bx_timeline_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
