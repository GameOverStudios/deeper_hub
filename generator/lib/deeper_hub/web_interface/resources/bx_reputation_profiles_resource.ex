defmodule DeeperHub.WebInterface.Resources.BxReputationProfiles do
  @moduledoc """
  Recurso REST para bx_reputation_profiles.
  Fornece endpoints para gerenciar bx_reputation_profiles.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReputationProfiles,
    resource_name: "bx_reputation_profile"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
