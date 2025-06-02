defmodule DeeperHub.WebInterface.Resources.BxGroupsFans do
  @moduledoc """
  Recurso REST para bx_groups_fans.
  Fornece endpoints para gerenciar bx_groups_fans.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxGroupsFans,
    resource_name: "bx_groups_fan"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
