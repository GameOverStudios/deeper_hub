defmodule DeeperHub.WebInterface.Resources.BxCreditsWithdrawals do
  @moduledoc """
  Recurso REST para bx_credits_withdrawals.
  Fornece endpoints para gerenciar bx_credits_withdrawals.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCreditsWithdrawals,
    resource_name: "bx_credits_withdrawal"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
