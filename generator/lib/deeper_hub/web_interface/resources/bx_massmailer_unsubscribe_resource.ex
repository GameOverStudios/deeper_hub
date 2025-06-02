defmodule DeeperHub.WebInterface.Resources.BxMassmailerUnsubscribe do
  @moduledoc """
  Recurso REST para bx_massmailer_unsubscribes.
  Fornece endpoints para gerenciar bx_massmailer_unsubscribes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMassmailerUnsubscribe,
    resource_name: "bx_massmailer_unsubscribe"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
