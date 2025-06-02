defmodule DeeperHub.WebInterface.Resources.BxDonationsEntries do
  @moduledoc """
  Recurso REST para bx_donations_entries.
  Fornece endpoints para gerenciar bx_donations_entries.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxDonationsEntries,
    resource_name: "bx_donations_entrie"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
