defmodule DeeperHub.WebInterface.Resources.BxDonationsEntriesDeleted do
  @moduledoc """
  Recurso REST para bx_donations_entries_deleteds.
  Fornece endpoints para gerenciar bx_donations_entries_deleteds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxDonationsEntriesDeleted,
    resource_name: "bx_donations_entries_deleted"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
