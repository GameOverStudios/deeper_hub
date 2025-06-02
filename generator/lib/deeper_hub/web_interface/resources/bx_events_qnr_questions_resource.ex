defmodule DeeperHub.WebInterface.Resources.BxEventsQnrQuestions do
  @moduledoc """
  Recurso REST para bx_events_qnr_questions.
  Fornece endpoints para gerenciar bx_events_qnr_questions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsQnrQuestions,
    resource_name: "bx_events_qnr_question"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
