defmodule DeeperHub.WebInterface.Resources.BxReputationProfilesLevels do
  @moduledoc """
  Recurso REST para bx_reputation_profiles_levels.
  Fornece endpoints para gerenciar bx_reputation_profiles_levels.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReputationProfilesLevels,
    resource_name: "bx_reputation_profiles_level"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
