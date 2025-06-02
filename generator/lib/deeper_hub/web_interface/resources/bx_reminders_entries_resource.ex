defmodule DeeperHub.WebInterface.Resources.BxRemindersEntries do
  @moduledoc """
  Recurso REST para bx_reminders_entries.
  Fornece endpoints para gerenciar bx_reminders_entries.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxRemindersEntries,
    resource_name: "bx_reminders_entrie"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
