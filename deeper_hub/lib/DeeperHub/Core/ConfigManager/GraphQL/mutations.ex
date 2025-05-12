defmodule DeeperHub.Core.ConfigManager.GraphQL.Mutations do
  @moduledoc """
  Mutations GraphQL para o ConfigManager.

  Define as operações de mutação que permitem alterar configurações do sistema.
  """

  use Absinthe.Schema.Notation

  alias DeeperHub.Core.ConfigManager

  @desc "Mutations relacionadas às configurações do sistema"
  object :config_mutations do
    @desc "Cria ou atualiza uma configuração"
    field :set_config, :setting do
      arg :input, non_null(:setting_input)

      resolve fn %{input: input}, _context ->
        # Converte os campos que podem ser átomos
        data_type = if input[:data_type], do: String.to_existing_atom(input[:data_type]), else: nil

        opts = [
          scope: input[:scope] || "global",
          data_type: data_type,
          description: input[:description] || "",
          is_sensitive: input[:is_sensitive] || false,
          created_by: input[:created_by] || "system"
        ]

        ConfigManager.set(input.key, input.value, opts)
      end
    end

    @desc "Remove uma configuração"
    field :delete_config, :setting do
      arg :key, non_null(:string), description: "Chave da configuração a ser removida"
      arg :scope, :string, description: "Escopo da configuração"
      arg :deleted_by, :string, description: "Quem está removendo a configuração"

      resolve fn args, _context ->
        scope = args[:scope] || "global"
        opts = [deleted_by: args[:deleted_by] || "system"]

        ConfigManager.delete(args.key, scope, opts)
      end
    end
  end
end
