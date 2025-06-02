defmodule DeeperHub.WebInterface.Resources.BxTimelineMute do
  @moduledoc """
  Recurso REST para bx_timeline_mutes.
  Fornece endpoints para gerenciar bx_timeline_mutes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineMute,
    resource_name: "bx_timeline_mute"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
