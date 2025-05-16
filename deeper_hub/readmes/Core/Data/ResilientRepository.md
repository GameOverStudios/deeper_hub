# Repositórios Resilientes com CircuitBreaker e Cache 🛡️📦

## Visão Geral

Este documento descreve como utilizar o módulo `ResilientRepository` do Deeper_Hub, que integra o CircuitBreaker e o Cache com o Repository para criar operações de banco de dados resilientes.

## Funcionalidades

* 🔄 Proteção de operações de banco de dados com CircuitBreaker
* 📦 Fallback automático para cache em operações de leitura
* ⏱️ Configuração de TTL para dados em cache
* 📊 Métricas detalhadas sobre operações de banco de dados
* 🔍 Logging aprimorado para diagnóstico de problemas
* 🔁 Políticas de retry para operações de escrita

## Inicialização

O `ResilientRepository` deve ser inicializado durante a inicialização da aplicação:

```elixir
# No módulo de inicialização da aplicação
def start(_type, _args) do
  # Inicializa o ResilientRepository
  Deeper_Hub.Core.Data.ResilientRepository.init([
    failure_threshold: 5,
    reset_timeout_ms: 30_000,
    cache_ttl: 3_600_000
  ])
  
  # Continua com a inicialização normal
  # ...
end
```

## Uso Básico

### Operações de Leitura com Fallback para Cache

```elixir
alias Deeper_Hub.Core.Data.ResilientRepository, as: Repo

# Buscar um usuário por ID
{:ok, user} = Repo.get(User, 123)

# Listar usuários ativos
{:ok, users} = Repo.list(User, [active: true])

# Encontrar usuários por critérios específicos
{:ok, admins} = Repo.find(User, [role: "admin"], [limit: 10])
```

### Operações de Escrita com Proteção de CircuitBreaker e Retry

```elixir
# Inserir um novo usuário
{:ok, user} = Repo.insert(User, %{
  name: "João Silva",
  email: "joao@example.com",
  role: "user"
})

# Atualizar um usuário existente
{:ok, updated_user} = Repo.update(user, %{role: "admin"})

# Deletar um usuário
{:ok, deleted_user} = Repo.delete(user)
```

## Opções Avançadas

### Controle de TTL para Cache

```elixir
# Buscar um usuário com TTL personalizado (30 minutos)
{:ok, user} = Repo.get(User, 123, [ttl: 1_800_000])
```

### Forçar Atualização do Cache

```elixir
# Buscar um usuário forçando atualização do cache
{:ok, user} = Repo.get(User, 123, [force_refresh: true])
```

### Controle de Retry para Operações de Escrita

```elixir
# Inserir um usuário com configuração personalizada de retry
{:ok, user} = Repo.insert(User, attrs, [
  max_retries: 5,
  retry_delay: 1000  # 1 segundo
])
```

### Controle de Invalidação de Cache

```elixir
# Atualizar um usuário sem invalidar o cache
{:ok, user} = Repo.update(user, attrs, [invalidate_cache: false])
```

## Padrões de Uso

### 1. Leitura com Fallback para Cache

Ideal para operações de leitura frequentes onde dados ligeiramente desatualizados são aceitáveis.

```elixir
def get_user_profile(user_id) do
  case ResilientRepository.get(User, user_id) do
    {:ok, user} ->
      # Processa o usuário
      {:ok, transform_user(user)}
      
    {:error, :not_found} ->
      # Usuário não encontrado
      {:error, :user_not_found}
      
    {:error, _reason} ->
      # Outro erro
      {:error, :service_unavailable}
  end
end
```

### 2. Operações de Escrita com Retry

Para operações de escrita onde falhas temporárias podem ocorrer.

```elixir
def create_user(attrs) do
  # Valida os atributos
  with {:ok, valid_attrs} <- validate_user_attrs(attrs),
       {:ok, user} <- ResilientRepository.insert(User, valid_attrs) do
    # Notifica sobre o novo usuário
    notify_user_created(user)
    {:ok, user}
  else
    {:error, %Ecto.Changeset{} = changeset} ->
      # Erro de validação
      {:error, format_changeset_errors(changeset)}
      
    {:error, _reason} ->
      # Erro de banco de dados
      {:error, :service_unavailable}
  end
end
```

### 3. Atualizações com Invalidação de Cache

Para operações de atualização que afetam múltiplas consultas.

```elixir
def update_user_role(user, new_role) do
  # Atualiza o usuário
  case ResilientRepository.update(user, %{role: new_role}) do
    {:ok, updated_user} ->
      # O cache para este usuário já foi invalidado automaticamente
      # Registra a alteração de papel
      log_role_change(user.id, user.role, new_role)
      {:ok, updated_user}
      
    {:error, _reason} ->
      {:error, :update_failed}
  end
end
```

### 4. Operações em Lote com Proteção

Para operações que afetam múltiplos registros.

```elixir
def deactivate_inactive_users(days_inactive) do
  # Encontra usuários inativos
  with {:ok, inactive_users} <- ResilientRepository.find(User, [
         last_login_before: days_ago(days_inactive)
       ]) do
    # Desativa cada usuário
    results = Enum.map(inactive_users, fn user ->
      ResilientRepository.update(user, %{active: false})
    end)
    
    # Conta sucessos e falhas
    successes = Enum.count(results, fn
      {:ok, _} -> true
      _ -> false
    end)
    
    failures = length(results) - successes
    
    # Retorna estatísticas
    {:ok, %{total: length(results), successes: successes, failures: failures}}
  else
    {:error, reason} ->
      {:error, reason}
  end
end

defp days_ago(days) do
  DateTime.utc_now() |> DateTime.add(-days * 86400, :second)
end
```

## Métricas e Monitoramento

O `ResilientRepository` emite as seguintes métricas:

| Métrica | Descrição |
|---------|-----------|
| `deeper_hub.core.data.resilient_repository.retry` | Incrementada quando uma operação é tentada novamente |
| `deeper_hub.core.circuit_breaker.cache_integration.cache_hit` | Incrementada quando um valor é encontrado no cache |
| `deeper_hub.core.circuit_breaker.cache_integration.fallback_hit` | Incrementada quando o fallback para cache é utilizado |
| `deeper_hub.core.circuit_breaker.cache_integration.complete_miss` | Incrementada quando a operação falha e não há valor em cache |
| `deeper_hub.core.circuit_breaker.cache_integration.origin_success` | Incrementada quando a operação principal é bem-sucedida |

## Boas Práticas

1. **Escolha TTLs Apropriados**: Defina TTLs baseados na natureza dos dados. Dados que mudam frequentemente devem ter TTLs curtos.

2. **Use Invalidação Seletiva**: Ao atualizar ou deletar registros, considere quais caches precisam ser invalidados.

3. **Monitore o Estado do CircuitBreaker**: Configure alertas para quando o CircuitBreaker abrir, indicando problemas com o banco de dados.

4. **Ajuste as Políticas de Retry**: Configure o número máximo de tentativas e o delay entre elas com base na natureza da operação e na carga do sistema.

5. **Considere a Consistência**: Para operações onde a consistência é crítica, use `force_refresh: true` para garantir dados atualizados.

## Troubleshooting

### Problema: Dados Desatualizados

**Solução**: Use a opção `force_refresh: true` para forçar a atualização do cache.

```elixir
{:ok, user} = ResilientRepository.get(User, user_id, [force_refresh: true])
```

### Problema: CircuitBreaker Sempre Aberto

**Solução**: Verifique o estado do CircuitBreaker e resete-o se necessário.

```elixir
alias Deeper_Hub.Core.CircuitBreaker.CircuitBreakerFacade, as: CB

# Verifica o estado
{:ok, state} = CB.state(:database_service)

# Se estiver aberto, reseta
if state == :open do
  CB.reset(:database_service)
end
```

### Problema: Erros de Validação Repetidos

**Solução**: Os erros de validação não são tentados novamente. Verifique os atributos antes de tentar a operação.

```elixir
# Valida antes de inserir
case validate_user_attrs(attrs) do
  {:ok, valid_attrs} ->
    ResilientRepository.insert(User, valid_attrs)
    
  {:error, reason} ->
    {:error, reason}
end
```

## Conclusão

O `ResilientRepository` fornece uma camada de resiliência para operações de banco de dados, combinando o CircuitBreaker para proteção contra falhas e o Cache como mecanismo de fallback. Ao seguir os padrões e boas práticas descritos neste documento, você pode melhorar significativamente a disponibilidade e performance do seu sistema, mesmo em situações de falha do banco de dados.
