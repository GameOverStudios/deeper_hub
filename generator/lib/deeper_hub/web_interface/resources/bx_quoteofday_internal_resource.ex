defmodule DeeperHub.WebInterface.Resources.BxQuoteofdayInternal do
  @moduledoc """
  Recurso REST para bx_quoteofday_internals.
  Fornece endpoints para gerenciar bx_quoteofday_internals.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxQuoteofdayInternal,
    resource_name: "bx_quoteofday_internal"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
