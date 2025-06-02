defmodule DeeperHub.WebInterface.Resources.BxClassesPollsAnswersVotes do
  @moduledoc """
  Recurso REST para bx_classes_polls_answers_votes.
  Fornece endpoints para gerenciar bx_classes_polls_answers_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesPollsAnswersVotes,
    resource_name: "bx_classes_polls_answers_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
