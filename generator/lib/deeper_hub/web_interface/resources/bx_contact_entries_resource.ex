defmodule DeeperHub.WebInterface.Resources.BxContactEntries do
  @moduledoc """
  Recurso REST para bx_contact_entries.
  Fornece endpoints para gerenciar bx_contact_entries.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxContactEntries,
    resource_name: "bx_contact_entrie"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
