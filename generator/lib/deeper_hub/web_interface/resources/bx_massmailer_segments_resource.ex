defmodule DeeperHub.WebInterface.Resources.BxMassmailerSegments do
  @moduledoc """
  Recurso REST para bx_massmailer_segments.
  Fornece endpoints para gerenciar bx_massmailer_segments.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMassmailerSegments,
    resource_name: "bx_massmailer_segment"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
