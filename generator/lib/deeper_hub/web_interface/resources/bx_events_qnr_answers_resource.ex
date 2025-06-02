defmodule DeeperHub.WebInterface.Resources.BxEventsQnrAnswers do
  @moduledoc """
  Recurso REST para bx_events_qnr_answers.
  Fornece endpoints para gerenciar bx_events_qnr_answers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsQnrAnswers,
    resource_name: "bx_events_qnr_answer"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
