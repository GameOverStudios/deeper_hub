defmodule DeeperHub.WebInterface.Resources.BxReviewsPollsAnswersVotes do
  @moduledoc """
  Recurso REST para bx_reviews_polls_answers_votes.
  Fornece endpoints para gerenciar bx_reviews_polls_answers_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsPollsAnswersVotes,
    resource_name: "bx_reviews_polls_answers_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
