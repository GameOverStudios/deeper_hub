defmodule DeeperHub.WebInterface.Resources.BxSpacesFans do
  @moduledoc """
  Recurso REST para bx_spaces_fans.
  Fornece endpoints para gerenciar bx_spaces_fans.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesFans,
    resource_name: "bx_spaces_fan"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
