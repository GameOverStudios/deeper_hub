defmodule DeeperHub.WebInterface.Resources.BxPostsPollsAnswers do
  @moduledoc """
  Recurso REST para bx_posts_polls_answers.
  Fornece endpoints para gerenciar bx_posts_polls_answers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPostsPollsAnswers,
    resource_name: "bx_posts_polls_answer"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
