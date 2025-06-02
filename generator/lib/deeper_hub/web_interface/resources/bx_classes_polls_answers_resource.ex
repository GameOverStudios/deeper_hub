defmodule DeeperHub.WebInterface.Resources.BxClassesPollsAnswers do
  @moduledoc """
  Recurso REST para bx_classes_polls_answers.
  Fornece endpoints para gerenciar bx_classes_polls_answers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesPollsAnswers,
    resource_name: "bx_classes_polls_answer"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
