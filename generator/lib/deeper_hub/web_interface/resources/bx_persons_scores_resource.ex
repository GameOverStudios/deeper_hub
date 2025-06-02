defmodule DeeperHub.WebInterface.Resources.BxPersonsScores do
  @moduledoc """
  Recurso REST para bx_persons_scores.
  Fornece endpoints para gerenciar bx_persons_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPersonsScores,
    resource_name: "bx_persons_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
