defmodule Deeper_Hub.Testes do
  @moduledoc """
  Módulo para testes de operações de banco de dados do Deeper_Hub.

  Este módulo contém funções para testar as operações CRUD e joins
  no banco de dados, usando os schemas User e Profile.

  Para executar todos os testes:

  ```
  mix run -e "Deeper_Hub.Testes.executar_todos()"
  ```

  Para executar um teste específico:

  ```
  mix run -e "Deeper_Hub.Testes.teste_usuarios()"
  ```
  """

  import Ecto.Query
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Schemas.User
  alias Deeper_Hub.Core.Schemas.Profile
  alias Deeper_Hub.Core.Logger

  @doc """
  Executa todos os testes sequencialmente.
  """
  def executar_todos do
    Logger.info("Iniciando testes...", %{module: __MODULE__})

    # Limpa o banco de dados antes dos testes
    limpar_banco_de_dados()

    # Primeiro testamos operações com usuários
    {user_id, _user} = teste_usuarios()

    # Depois testamos operações com perfis
    teste_perfis(user_id)

    # Por fim, testamos operações de join
    teste_joins(user_id)

    Logger.info("Todos os testes concluídos com sucesso!", %{module: __MODULE__})
  end

  defp limpar_banco_de_dados do
    Logger.info("Limpando banco de dados...", %{module: __MODULE__})

    # Remove todos os perfis
    Repo.delete_all(Profile)

    # Remove todos os usuários
    Repo.delete_all(User)

    Logger.info("Banco de dados limpo!", %{module: __MODULE__})
  end

  @doc """
  Testa operações CRUD com usuários.

  Retorna o ID do usuário criado e o próprio usuário.
  """
  def teste_usuarios do
    Logger.info("Iniciando testes de usuários...", %{module: __MODULE__})

    # 1. Criar um usuário com dados únicos
    user = %User{
      username: "user_#{System.unique_integer([:positive])}",
      email: "user_#{System.unique_integer([:positive])}@email.com",
      password: "senha123"
    }

    # 2. Criar changeset e inserir usuário
    {_user_id, user_found} = 
      case User.changeset(user, %{}) |> Repo.insert() do
        {:ok, user_inserted} ->
          user_id = user_inserted.id
          Logger.info("Usuário criado com ID: #{user_id}", %{module: __MODULE__})

          # 3. Buscar usuário por ID
          case Repo.get(User, user_id) do
            nil ->
              Logger.error("Usuário não encontrado com ID: #{user_id}", %{module: __MODULE__})
              raise "Usuário não encontrado com ID: #{user_id}"
            found_user ->
              Logger.info("Usuário encontrado: #{found_user.username}", %{module: __MODULE__})
              {user_id, found_user}
          end
        {:error, changeset} ->
          Logger.error("Erro ao criar usuário: #{inspect(changeset.errors)}", %{module: __MODULE__})
          raise "Erro ao criar usuário: #{inspect(changeset.errors)}"
      end

    # 4. Buscar todos os usuários ativos
    usuarios_ativos = Repo.all(from u in User, where: u.is_active == true)
    Logger.info("Usuários ativos encontrados: #{length(usuarios_ativos)}", %{module: __MODULE__})

    # 5. Buscar com paginação usando Scrivener
    query = from u in User, where: u.is_active == true
    page_params = %{page: 1, page_size: 10, sort_field: :username, sort_order: :asc}
    
    page = Deeper_Hub.Core.Data.Paginator.paginate_module(query, page_params, :users)
    Logger.info("Página #{page.page_number} de #{page.total_pages}", %{module: __MODULE__})
    Logger.info("Total de usuários: #{page.total_entries}", %{module: __MODULE__})
    Logger.info("Usuários na página atual: #{length(page.entries)}", %{module: __MODULE__})

    # 6. Atualizar usuário
    new_email = "updated_#{System.unique_integer([:positive])}@email.com"
    updated_user = %{user_found | email: new_email}

    {:ok, updated_user} = User.changeset(updated_user, %{email: new_email}) |> Repo.update()
    Logger.info("Usuário atualizado com sucesso", %{module: __MODULE__})

    # 7. Desativar usuário
    {:ok, deactivated_user} = User.changeset(updated_user, %{is_active: false}) |> Repo.update()
    Logger.info("Usuário desativado com sucesso", %{module: __MODULE__})

    # 8. Buscar usuários desativados
    usuarios_desativados = Repo.all(from u in User, where: u.is_active == false)
    Logger.info("Usuários desativados encontrados: #{length(usuarios_desativados)}", %{module: __MODULE__})

    # 9. Reativar usuário para os próximos testes
    {:ok, reactivated_user} = User.changeset(deactivated_user, %{is_active: true}) |> Repo.update()
    Logger.info("Usuário reativado com sucesso", %{module: __MODULE__})

    Logger.info("Testes de usuários concluídos com sucesso!", %{module: __MODULE__})

    {reactivated_user.id, reactivated_user}
  end

  @doc """
  Testa operações CRUD com perfis.

  Recebe o ID do usuário para criar um perfil associado.
  """
  def teste_perfis(user_id) do
    Logger.info("Iniciando testes de perfis...", %{module: __MODULE__})

    # 1. Criar um perfil para o usuário
    profile = %Profile{
      user_id: user_id,
      profile_picture: "https://exemplo.com/perfil.jpg",
      bio: "Desenvolvedora de software",
      website: "https://maria.dev"
    }

    # 2. Criar changeset e inserir perfil
    profile_changeset = Profile.changeset(profile, %{})
    {:ok, profile_inserted} = Repo.insert(profile_changeset)
    profile_id = profile_inserted.id

    Logger.info("Perfil criado com ID: #{profile_id}", %{module: __MODULE__})

    # 3. Buscar perfil por ID
    profile_found = Repo.get(Profile, profile_id)
    Logger.info("Perfil encontrado para usuário: #{profile_found.user_id}", %{module: __MODULE__})

    # 4. Atualizar perfil
    updated_profile = %{profile_found | bio: "Desenvolvedora de software e entusiasta de Elixir"}
    {:ok, _} = Repo.update(Profile.changeset(updated_profile, %{bio: "Desenvolvedora de software e entusiasta de Elixir"}))
    Logger.info("Perfil atualizado com sucesso", %{module: __MODULE__})

    Logger.info("Testes de perfis concluídos com sucesso!", %{module: __MODULE__})

    profile_id
  end

  @doc """
  Testa operações de join entre usuários e perfis.

  Recebe o ID do usuário para realizar os joins.
  """
  def teste_joins(_user_id) do
    Logger.info("Iniciando testes de joins...", %{module: __MODULE__})

    # 1. Inner Join (retorna apenas registros que existem em ambas as tabelas)
    query = from u in User,
      inner_join: p in Profile,
      on: u.id == p.user_id,
      select: %{username: u.username, email: u.email, profile_picture: p.profile_picture}
    inner_join_results = Repo.all(query)
    Logger.info("Inner Join: #{length(inner_join_results)} resultados", %{module: __MODULE__})

    # 2. Left Join (retorna todos os registros da tabela da esquerda)
    query = from u in User,
      left_join: p in Profile,
      on: u.id == p.user_id,
      select: %{username: u.username, email: u.email, profile_picture: p.profile_picture}
    left_join_results = Repo.all(query)
    Logger.info("Left Join: #{length(left_join_results)} resultados", %{module: __MODULE__})

    # 3. Right Join (retorna todos os registros da tabela da direita)
    query = from u in User,
      right_join: p in Profile,
      on: u.id == p.user_id,
      select: %{username: u.username, email: u.email, profile_picture: p.profile_picture}
    right_join_results = Repo.all(query)
    Logger.info("Right Join: #{length(right_join_results)} resultados", %{module: __MODULE__})

    # 4. Join com condições adicionais
    query = from u in User,
      inner_join: p in Profile,
      on: u.id == p.user_id,
      where: u.is_active == true and not is_nil(p.website),
      limit: 10,
      offset: 0,
      order_by: [desc: u.username],
      select: %{username: u.username, website: p.website}
    conditional_join_results = Repo.all(query)
    Logger.info("Join com condições: #{length(conditional_join_results)} resultados", %{module: __MODULE__})

    Logger.info("Testes de joins concluídos com sucesso!", %{module: __MODULE__})
  end
end
