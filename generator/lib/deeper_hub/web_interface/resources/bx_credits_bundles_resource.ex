defmodule DeeperHub.WebInterface.Resources.BxCreditsBundles do
  @moduledoc """
  Recurso REST para bx_credits_bundles.
  Fornece endpoints para gerenciar bx_credits_bundles.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCreditsBundles,
    resource_name: "bx_credits_bundle"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
