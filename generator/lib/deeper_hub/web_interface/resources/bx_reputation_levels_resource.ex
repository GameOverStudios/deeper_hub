defmodule DeeperHub.WebInterface.Resources.BxReputationLevels do
  @moduledoc """
  Recurso REST para bx_reputation_levels.
  Fornece endpoints para gerenciar bx_reputation_levels.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReputationLevels,
    resource_name: "bx_reputation_level"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
