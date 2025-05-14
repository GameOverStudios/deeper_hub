# DeeperHub

DeeperHub é uma plataforma de gerenciamento de dados em Elixir que fornece uma interface simplificada para operações de banco de dados, com suporte a cache e consultas otimizadas.

## Características Principais

- **Repositório Genérico**: Interface unificada para operações CRUD em qualquer schema Ecto
- **Sistema de Cache**: Melhora o desempenho de consultas repetitivas com cache automático
- **Operações de Join**: Suporte a inner, left e right joins com API simplificada
- **Consultas Flexíveis**: Filtros dinâmicos, ordenação e paginação
- **Arquitetura Modular**: Código organizado em módulos com responsabilidades específicas

## Arquitetura

O sistema é dividido em três módulos principais:

1. **RepositoryCore**: Gerencia o cache e fornece funções auxiliares
2. **RepositoryCrud**: Implementa operações CRUD básicas (Create, Read, Update, Delete)
3. **RepositoryJoins**: Fornece operações de join entre tabelas

O módulo `Repository` funciona como uma fachada (Facade) que delega chamadas para os módulos específicos.

## Exemplos de Uso no IEx

Abaixo estão exemplos práticos de como utilizar o DeeperHub no console interativo do Elixir (IEx).

### Iniciar o IEx com a Aplicação

```bash
iex -S mix
```

### Operações CRUD Básicas

#### Inserir um Registro

```elixir
# Supondo que você tenha um schema User
alias Deeper_Hub.Core.Data.Repository
alias MyApp.User

# Inserir um novo usuário
{:ok, user} = Repository.insert(User, %{name: "João Silva", email: "joao@example.com", active: true})
```

#### Buscar um Registro por ID

```elixir
# Buscar um usuário pelo ID
{:ok, user} = Repository.get(User, 1)

# O resultado é armazenado em cache automaticamente para consultas futuras
```

#### Atualizar um Registro

```elixir
# Primeiro, busque o registro
{:ok, user} = Repository.get(User, 1)

# Depois, atualize-o
{:ok, updated_user} = Repository.update(user, %{name: "João Santos"})
```

#### Excluir um Registro

```elixir
# Primeiro, busque o registro
{:ok, user} = Repository.get(User, 1)

# Depois, exclua-o
{:ok, :deleted} = Repository.delete(user)
```

### Listagem e Consultas

#### Listar Todos os Registros

```elixir
# Listar todos os usuários
{:ok, users} = Repository.list(User)

# Listar com limite e deslocamento (paginação)
{:ok, users} = Repository.list(User, limit: 10, offset: 0)

# Listar com pré-carregamento de associações
{:ok, users} = Repository.list(User, preload: [:profile, :posts])

# Listar com ordenação personalizada
{:ok, users} = Repository.list(User, order_by: [desc: :inserted_at])
```

#### Buscar Registros com Condições

```elixir
# Buscar usuários ativos
{:ok, active_users} = Repository.find(User, %{active: true})

# Buscar com múltiplas condições
{:ok, users} = Repository.find(User, %{active: true, role: "admin"})

# Buscar com operadores especiais
# Valores nulos
{:ok, users} = Repository.find(User, %{deleted_at: nil})

# Valores não nulos
{:ok, users} = Repository.find(User, %{email: :not_nil})

# Busca por lista de valores (IN)
{:ok, users} = Repository.find(User, %{role: {:in, ["admin", "editor"]}})

# Exclusão de lista de valores (NOT IN)
{:ok, users} = Repository.find(User, %{role: {:not_in, ["guest", "viewer"]}})

# Busca com LIKE (case-sensitive)
{:ok, users} = Repository.find(User, %{name: {:like, "Silva"}})

# Busca com ILIKE (case-insensitive)
{:ok, users} = Repository.find(User, %{name: {:ilike, "silva"}})

# Combinando com paginação
{:ok, users} = Repository.find(User, %{active: true}, limit: 10, offset: 0)
```

### Operações de Join

#### Inner Join

```elixir
# Inner join entre User e Profile
{:ok, results} = Repository.join_inner(
  User,
  Profile,
  [:id, :name, :email, :profile_picture, :bio],
  %{active: true},
  join_on: {:id, :user_id}
)

# O parâmetro join_on especifica os campos para a condição de join
# No exemplo acima: User.id = Profile.user_id
```

#### Left Join

```elixir
# Left join entre User e Profile
# Retorna todos os usuários, mesmo os que não têm perfil
{:ok, results} = Repository.join_left(
  User,
  Profile,
  [:id, :name, :email, :profile_picture, :bio],
  %{active: true},
  join_on: {:id, :user_id}
)
```

#### Right Join

```elixir
# Right join entre User e Profile
# Retorna todos os perfis, mesmo os que não estão associados a um usuário
{:ok, results} = Repository.join_right(
  User,
  Profile,
  [:id, :name, :email, :profile_picture, :bio],
  %{active: true},
  join_on: {:id, :user_id}
)
```

### Gerenciamento de Cache

#### Estatísticas de Cache

```elixir
# Obter estatísticas de uso do cache
stats = Repository.get_cache_stats()
# Retorna um mapa com hits, misses e hit_rate
```

#### Invalidar Cache

```elixir
# Invalidar o cache para um registro específico
:ok = Repository.invalidate_cache(User, 1)
```

## Configuração

O DeeperHub é configurado automaticamente na inicialização da aplicação. O cache é inicializado e gerenciado pelo módulo `RepositoryCore`, que é supervisionado pela árvore de supervisão principal.

## Boas Práticas

1. **Use a Fachada**: Sempre acesse as funcionalidades através do módulo `Repository` em vez de chamar diretamente os módulos específicos.

2. **Aproveite o Cache**: O sistema de cache é automático para operações de leitura. Use `Repository.get/2` para aproveitar o cache.

3. **Consultas Eficientes**: Use `find/3` com condições específicas em vez de buscar todos os registros e filtrar na aplicação.

4. **Paginação**: Sempre use paginação (limit e offset) ao lidar com grandes conjuntos de dados.

5. **Joins Seletivos**: Ao usar joins, selecione apenas os campos necessários para melhorar o desempenho.

## Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Faça commit das suas alterações (`git commit -am 'Adiciona nova funcionalidade'`)
4. Faça push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request
