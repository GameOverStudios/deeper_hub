defmodule DeeperHub.Core.ConfigManager.GraphQL.Types do
  @moduledoc """
  Tipos GraphQL para o ConfigManager.

  Define os tipos GraphQL relacionados às configurações do sistema.
  """

  use Absinthe.Schema.Notation

  @desc "Tipo de dados de uma configuração"
  enum :config_data_type do
    value :string, description: "Tipo string"
    value :integer, description: "Tipo inteiro"
    value :float, description: "Tipo ponto flutuante"
    value :boolean, description: "Tipo booleano"
    value :list, description: "Tipo lista"
    value :map, description: "Tipo mapa/objeto"
  end

  @desc "Uma configuração do sistema"
  object :setting do
    field :id, :id, description: "ID único da configuração"
    field :key, :string, description: "Chave da configuração"
    field :value, :string, description: "Valor da configuração como string"
    field :scope, :string, description: "Escopo da configuração"
    field :data_type, :config_data_type, description: "Tipo de dado da configuração"
    field :is_sensitive, :boolean, description: "Indica se a configuração é sensível"
    field :description, :string, description: "Descrição da configuração"
    field :created_by, :string, description: "Quem criou a configuração"
    field :inserted_at, :string, description: "Data de criação"
    field :updated_at, :string, description: "Data de atualização"
  end

  @desc "Parâmetros de entrada para criar ou atualizar uma configuração"
  input_object :setting_input do
    field :key, non_null(:string), description: "Chave da configuração"
    field :value, non_null(:string), description: "Valor da configuração"
    field :scope, :string, description: "Escopo da configuração"
    field :data_type, :config_data_type, description: "Tipo de dado da configuração"
    field :is_sensitive, :boolean, description: "Indica se a configuração é sensível"
    field :description, :string, description: "Descrição da configuração"
    field :created_by, :string, description: "Quem está criando a configuração"
  end
end
