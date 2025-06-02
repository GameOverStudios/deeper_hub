defmodule DeeperHub.WebInterface.Resources.BxClassesVotes do
  @moduledoc """
  Recurso REST para bx_classes_votes.
  Fornece endpoints para gerenciar bx_classes_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesVotes,
    resource_name: "bx_classes_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
