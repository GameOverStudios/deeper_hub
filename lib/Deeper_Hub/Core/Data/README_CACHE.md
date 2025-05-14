# Mu00f3dulo de Cache para Consultas Mnesia

## Visu00e3o Geral

O mu00f3dulo `Deeper_Hub.Core.Data.Cache` implementa um sistema de cache em memu00f3ria para otimizar consultas ao banco de dados Mnesia. Este cache armazena temporariamente os resultados de operau00e7u00f5es de leitura frequentes, reduzindo a carga no banco de dados e melhorando o desempenho geral do sistema.

## Responsabilidades

- Armazenar resultados de consultas ao Mnesia em memu00f3ria
- Gerenciar a expirau00e7u00e3o de entradas de cache com base em TTL (Time-To-Live)
- Invalidar entradas de cache quando os dados subjacentes su00e3o modificados
- Fornecer estatu00edsticas sobre a eficu00e1cia do cache (hits, misses, hit rate)
- Integrar-se com o mu00f3dulo Repository para interceptar e cachear consultas

## Funcionalidades Chave

### Armazenamento e Recuperau00e7u00e3o

- `put/4` e `put/5`: Armazena um valor no cache com TTL opcional
- `get/3`: Recupera um valor do cache se existir e nu00e3o estiver expirado

### Invalidau00e7u00e3o de Cache

- `invalidate/1`: Invalida todas as entradas de uma tabela especu00edfica
- `invalidate/2`: Invalida todas as entradas de uma tabela para uma operau00e7u00e3o especu00edfica
- `invalidate/3`: Invalida uma entrada especu00edfica do cache
- `clear/0`: Limpa todo o cache

### Estatu00edsticas

- `stats/0`: Retorna estatu00edsticas sobre o uso do cache (tamanho, hits, misses, hit rate)

## Integrau00e7u00e3o com Repository

O mu00f3dulo de cache u00e9 integrado com o `Repository` para:

1. Verificar o cache antes de realizar consultas ao banco de dados
2. Armazenar resultados de consultas no cache
3. Invalidar entradas de cache quando registros su00e3o modificados (insert, update, delete)

## Estrutura de Dados

O cache utiliza uma estrutura de dados em memu00f3ria com o seguinte formato:

```elixir
%{
  cache: %{
    {table_name, operation, key} => %{
      value: cached_value,
      expires_at: timestamp
    }
  },
  hits: count,
  misses: count
}
```

Onde:
- `table_name`: Nome da tabela Mnesia (ex: `:users`)
- `operation`: Tipo de operau00e7u00e3o (ex: `:find`, `:all`, `:match`)
- `key`: Chave do registro ou paru00e2metros da consulta
- `cached_value`: Valor armazenado em cache
- `expires_at`: Timestamp de expirau00e7u00e3o (em milissegundos)

## Configurau00e7u00e3o

O mu00f3dulo de cache utiliza um TTL padru00e3o de 60 segundos para entradas de cache, mas permite especificar um TTL personalizado para cada entrada.

## Exemplos de Uso

### Uso Direto

```elixir
# Armazenar um valor no cache
Cache.put(:users, :find, 1, {:ok, user_record})

# Recuperar um valor do cache
case Cache.get(:users, :find, 1) do
  {:ok, cached_result} -> cached_result
  :not_found -> # buscar do banco de dados
end

# Invalidar cache apu00f3s modificau00e7u00e3o
Cache.invalidate(:users, :find, 1)
```

### Uso Automu00e1tico via Repository

O cache u00e9 usado automaticamente pelo Repository:

```elixir
# Buscar um registro (verifica o cache primeiro)
{:ok, user} = Repository.find(:users, 1)

# Atualizar um registro (invalida o cache automaticamente)
{:ok, updated_user} = Repository.update(:users, updated_record)
```

## Considerau00e7u00f5es de Desempenho

- O cache u00e9 mantido em memu00f3ria e nu00e3o persiste apu00f3s reinicializau00e7u00f5es
- Entradas de cache expiram automaticamente apu00f3s seu TTL
- O TTL para resultados `:not_found` u00e9 menor (30 segundos) para evitar cache negativo prolongado
- O cache u00e9 invalidado automaticamente apu00f3s operau00e7u00f5es de escrita para manter a consistu00eancia

## Mu00e9tricas e Monitoramento

O mu00f3dulo de cache integra-se com o sistema de mu00e9tricas existente para registrar:

- Cache hits e misses
- Tempo economizado por operau00e7u00f5es em cache
- Taxa de acerto do cache (hit rate)
