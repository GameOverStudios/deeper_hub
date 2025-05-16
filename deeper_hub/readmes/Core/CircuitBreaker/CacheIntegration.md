# Integração CircuitBreaker e Cache 🔄📦

## Visão Geral

Este documento descreve como utilizar a integração entre os módulos CircuitBreaker e Cache do Deeper_Hub para criar operações resilientes com fallback automático para dados em cache.

## Funcionalidades

* 🔄 Execução de operações com fallback automático para cache
* 📦 Armazenamento automático de resultados bem-sucedidos no cache
* ⏱️ Configuração de TTL para dados em cache
* 📊 Métricas detalhadas sobre hits/misses de cache durante fallbacks
* 🔍 Logging aprimorado para diagnóstico de problemas

## Instalação

A integração entre CircuitBreaker e Cache já está disponível como parte do Deeper_Hub Core. Não é necessária nenhuma instalação adicional.

## Uso Básico

### Operação com Fallback para Cache

```elixir
alias Deeper_Hub.Core.CircuitBreaker.CacheIntegration

# Executar operação com fallback para cache
CacheIntegration.with_cache_fallback(
  :external_api,           # Nome do serviço
  "get_user_data",         # Nome da operação
  "user:123",              # Chave de cache
  fn -> 
    # Função que busca os dados do serviço externo
    {:ok, HTTPClient.get("https://api.example.com/users/123")}
  end,
  :user_cache,             # Nome do cache
  [ttl: 3600000]           # Opções (TTL de 1 hora)
)
```

### Operação com Transformação de Dados

```elixir
# Executar operação com transformação de dados antes de armazenar no cache
CacheIntegration.with_cache_fallback_transform(
  :external_api, 
  "get_user_profile",
  "user:123",
  fn -> 
    {:ok, HTTPClient.get("https://api.example.com/users/123")}
  end,
  fn {:ok, data} -> 
    # Transforma os dados antes de armazenar no cache
    # Por exemplo, remove dados sensíveis
    {:ok, Map.take(data, [:id, :name, :email])}
  end,
  :user_cache,
  [ttl: 86400000] # 24 horas
)
```

### Invalidação e Atualização de Cache

```elixir
# Invalida uma entrada no cache e força uma atualização
CacheIntegration.invalidate_and_refresh(
  :external_api, 
  "get_user_profile",
  "user:123",
  fn -> 
    {:ok, HTTPClient.get("https://api.example.com/users/123")}
  end,
  :user_cache
)
```

## Opções de Configuração

A função `with_cache_fallback` aceita as seguintes opções:

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `:ttl` | `integer` | `3600000` | Tempo de vida do item no cache em milissegundos (1 hora por padrão) |
| `:stale_fallback` | `boolean` | `true` | Se `true`, usa dados em cache mesmo se expirados quando o serviço falhar |
| `:skip_cache_check` | `boolean` | `false` | Se `true`, sempre tenta a operação principal primeiro sem verificar o cache |
| `:force_refresh` | `boolean` | `false` | Se `true`, força a execução da operação principal e atualiza o cache |
| `:circuit_breaker_opts` | `Keyword.t()` | `[]` | Opções específicas para o CircuitBreaker |

## Padrões de Uso

### 1. Acesso a APIs Externas

Ideal para chamadas a APIs externas onde você deseja continuar fornecendo dados mesmo quando a API estiver indisponível.

```elixir
def get_weather(city) do
  CacheIntegration.with_cache_fallback(
    :weather_api,
    "get_weather",
    "weather:#{city}",
    fn -> 
      WeatherClient.get_current(city)
    end,
    :weather_cache,
    [ttl: 1800000] # 30 minutos
  )
end
```

### 2. Consultas de Banco de Dados Pesadas

Para consultas de banco de dados que são computacionalmente caras e onde dados ligeiramente desatualizados são aceitáveis.

```elixir
def get_user_statistics(user_id) do
  CacheIntegration.with_cache_fallback(
    :database,
    "user_statistics",
    "stats:#{user_id}",
    fn -> 
      {:ok, UserStatisticsRepo.calculate_for_user(user_id)}
    end,
    :statistics_cache,
    [ttl: 86400000] # 24 horas
  )
end
```

### 3. Dados com Diferentes Níveis de Frescor

Para casos onde você precisa de dados sempre atualizados em algumas situações, mas pode usar cache em outras.

```elixir
def get_product_details(product_id, force_fresh \\ false) do
  options = if force_fresh do
    [skip_cache_check: true]
  else
    []
  end
  
  CacheIntegration.with_cache_fallback(
    :product_service,
    "get_product",
    "product:#{product_id}",
    fn -> 
      ProductService.get_details(product_id)
    end,
    :product_cache,
    options
  )
end
```

### 4. Sanitização de Dados Sensíveis

Para casos onde você precisa remover dados sensíveis antes de armazenar no cache.

```elixir
def get_user_profile(user_id) do
  CacheIntegration.with_cache_fallback_transform(
    :user_service,
    "get_profile",
    "profile:#{user_id}",
    fn -> 
      UserService.get_profile(user_id)
    end,
    fn {:ok, profile} -> 
      # Remove dados sensíveis antes de armazenar no cache
      sanitized = profile
        |> Map.delete(:password_hash)
        |> Map.delete(:security_question)
        |> Map.update(:phone, nil, &mask_phone/1)
      
      {:ok, sanitized}
    end,
    :user_cache
  )
end

defp mask_phone(nil), do: nil
defp mask_phone(phone) do
  # Mantém apenas os últimos 4 dígitos visíveis
  if String.length(phone) > 4 do
    masked = String.duplicate("*", String.length(phone) - 4)
    masked <> String.slice(phone, -4..-1)
  else
    phone
  end
end
```

## Métricas e Monitoramento

A integração entre CircuitBreaker e Cache emite as seguintes métricas:

| Métrica | Descrição |
|---------|-----------|
| `deeper_hub.core.circuit_breaker.cache_integration.cache_hit` | Incrementada quando um valor é encontrado no cache |
| `deeper_hub.core.circuit_breaker.cache_integration.fallback_hit` | Incrementada quando o fallback para cache é utilizado |
| `deeper_hub.core.circuit_breaker.cache_integration.complete_miss` | Incrementada quando a operação falha e não há valor em cache |
| `deeper_hub.core.circuit_breaker.cache_integration.origin_success` | Incrementada quando a operação principal é bem-sucedida |

## Eventos

A integração emite os seguintes eventos:

| Evento | Payload | Descrição |
|--------|---------|-----------|
| `circuit_breaker.cache_fallback` | `%{service_name, operation_name, cache_key, timestamp}` | Emitido quando o fallback para cache é utilizado |

## Boas Práticas

1. **Escolha TTLs Apropriados**: Defina TTLs baseados na natureza dos dados. Dados que mudam frequentemente devem ter TTLs curtos.

2. **Use Chaves de Cache Específicas**: Evite chaves genéricas. Use chaves que incluam todos os parâmetros relevantes para a operação.

3. **Sanitize Dados Sensíveis**: Sempre use `with_cache_fallback_transform` para remover dados sensíveis antes de armazenar no cache.

4. **Monitore as Métricas**: Configure alertas para métricas como `complete_miss` para identificar quando tanto o serviço quanto o cache estão falhando.

5. **Considere Invalidação Proativa**: Em sistemas onde a consistência é importante, implemente invalidação proativa do cache quando os dados mudam.

## Troubleshooting

### Problema: Dados Desatualizados no Cache

**Solução**: Use a opção `force_refresh: true` para forçar a atualização do cache, ou `invalidate_and_refresh` para invalidar e atualizar explicitamente.

### Problema: CircuitBreaker Sempre Aberto

**Solução**: Verifique se a função de operação está retornando corretamente `{:ok, result}` para sucessos e `{:error, reason}` para falhas.

### Problema: Alto Uso de Memória no Cache

**Solução**: Revise os TTLs e considere usar a função `Cache.purge/1` periodicamente para remover entradas expiradas.

## Conclusão

A integração entre CircuitBreaker e Cache fornece uma solução robusta para criar operações resilientes que podem continuar funcionando mesmo quando serviços externos estão indisponíveis. Ao seguir os padrões e boas práticas descritos neste documento, você pode melhorar significativamente a disponibilidade e performance do seu sistema.
