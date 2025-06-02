defmodule DeeperHub.WebInterface.Resources.BxMassmailerLetters do
  @moduledoc """
  Recurso REST para bx_massmailer_letters.
  Fornece endpoints para gerenciar bx_massmailer_letters.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMassmailerLetters,
    resource_name: "bx_massmailer_letter"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
