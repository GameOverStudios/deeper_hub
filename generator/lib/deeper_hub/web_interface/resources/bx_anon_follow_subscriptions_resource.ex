defmodule DeeperHub.WebInterface.Resources.BxAnonFollowSubscriptions do
  @moduledoc """
  Recurso REST para bx_anon_follow_subscriptions.
  Fornece endpoints para gerenciar bx_anon_follow_subscriptions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAnonFollowSubscriptions,
    resource_name: "bx_anon_follow_subscription"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
