defmodule DeeperHub.WebInterface.Resources.BxGlossaryReactions do
  @moduledoc """
  Recurso REST para bx_glossary_reactions.
  Fornece endpoints para gerenciar bx_glossary_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxGlossaryReactions,
    resource_name: "bx_glossary_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
