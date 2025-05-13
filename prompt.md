# Diretrizes de Codificação para o Projeto DeeperHub 🚀

## Introdução

Este documento estabelece as diretrizes e práticas recomendadas para o desenvolvimento do projeto DeeperHub. Seu objetivo é minimizar erros de desenvolvimento, garantir consistência no código e assegurar que todas as implementações sigam fielmente as especificações descritas nos arquivos README de cada módulo.

## 🔍 Conformidade com Especificações

### Antes de Iniciar o Desenvolvimento

1. **Leia completamente o README do módulo**: Antes de iniciar qualquer implementação, leia integralmente o README do módulo para compreender:
   - Responsabilidades e funcionalidades esperadas
   - Estrutura de diretórios recomendada
   - Dependências e integrações com outros módulos
   - Padrões de design a serem seguidos

2. **Não crie módulos não especificados**: 
   - ⚠️ **IMPORTANTE**: Não crie novos módulos que não estejam previamente especificados nos documentos de requisitos ou READMEs.
   - Se identificar a necessidade de um novo módulo, documente a proposta e discuta com a equipe antes da implementação.

3. **Respeite a arquitetura definida**:
   - Mantenha a separação de responsabilidades conforme definido na arquitetura
   - Não adicione dependências desnecessárias entre módulos
   - Siga os padrões de design especificados (ex: Facade, Repository, Service)

### Durante o Desenvolvimento

1. **Implemente todas as funcionalidades especificadas**:
   - Verifique cada item listado nas seções "Responsabilidades" e "Funcionalidades Chave"
   - Garanta que todos os casos de uso descritos sejam implementados

2. **Mantenha a consistência com a documentação**:
   - Use os mesmos nomes de funções, parâmetros e tipos mencionados na documentação
   - Implemente as interfaces públicas conforme especificado
   - Documente quaisquer desvios necessários das especificações originais

3. **Siga as convenções de nomenclatura**:
   - Use nomes descritivos e significativos
   - Siga o padrão de nomenclatura do Elixir (snake_case para variáveis e funções)
   - Mantenha consistência com os nomes já utilizados no projeto

## 🧹 Revisão de Código e Limpeza

### ⚠️ EXTREMAMENTE IMPORTANTE: Revisão Pós-Implementação

**Após concluir a implementação de cada arquivo, realize uma revisão rigorosa para:**

1. **Remover código não utilizado**:
   - Variáveis declaradas mas não utilizadas
   - Funções definidas mas nunca chamadas
   - Importações e aliases não utilizados
   - Parâmetros de funções que não são utilizados no corpo da função

2. **Verificar implementações incompletas**:
   - Funções declaradas mas não implementadas
   - Chamadas a funções que não existem
   - TODOs ou FIXMEs deixados no código
   - Implementações parciais de interfaces ou comportamentos

3. **Corrigir problemas de tipagem**:
   - Especificações de tipo (@spec) incorretas ou incompletas
   - Retornos de função incompatíveis com a especificação
   - Parâmetros com tipos incorretos

4. **Eliminar avisos de compilação**:
   - Resolver todos os warnings do compilador
   - Corrigir problemas de depreciação
   - Eliminar avisos de dialyzer

### Checklist de Revisão

Utilize esta checklist após cada implementação ou correção:

- [ ] Todas as variáveis declaradas são utilizadas
- [ ] Todos os imports e aliases são necessários
- [ ] Todos os parâmetros de funções são utilizados
- [ ] Todas as funções declaradas estão implementadas
- [ ] Não existem chamadas a funções inexistentes
- [ ] Todas as especificações de tipo estão corretas
- [ ] Não há avisos de compilação
- [ ] O código está formatado de acordo com o estilo do projeto
- [ ] Os testes cobrem todas as funcionalidades implementadas
- [ ] A documentação está atualizada e reflete a implementação atual

## 🧪 Testes

1. **Teste todas as funcionalidades implementadas**:
   - Crie testes unitários para cada função pública
   - Implemente testes de integração para fluxos completos
   - Verifique casos de borda e condições de erro

2. **Mantenha a cobertura de testes alta**:
   - Busque uma cobertura de código de pelo menos 80%
   - Priorize testar lógica complexa e tratamento de erros
   - Não deixe funções públicas sem testes

3. **Testes devem ser independentes e determinísticos**:
   - Cada teste deve poder ser executado isoladamente
   - Evite dependências entre testes
   - Use mocks e stubs para isolar o código sendo testado

## 📝 Documentação

1. **Mantenha a documentação atualizada**:
   - Atualize a documentação quando alterar interfaces públicas
   - Adicione exemplos de uso para novas funcionalidades
   - Documente comportamentos não óbvios ou complexos

2. **Documente todas as funções públicas**:
   - Use @moduledoc para documentar módulos
   - Use @doc para documentar funções públicas
   - Inclua exemplos de uso quando apropriado
   - Documente parâmetros e valores de retorno

## 🔄 Processo de Desenvolvimento

1. **Desenvolvimento Iterativo**:
   - Implemente uma funcionalidade por vez
   - Teste cada funcionalidade antes de passar para a próxima
   - Refatore conforme necessário para manter a qualidade do código

2. **Revisão Regular**:
   - Revise o código após cada implementação significativa
   - Use ferramentas automáticas de análise de código
   - Solicite revisões de código de outros desenvolvedores quando possível

3. **Integração Contínua**:
   - Execute os testes automatizados frequentemente
   - Verifique a cobertura de código regularmente
   - Corrija falhas de teste imediatamente

## 🛠️ Ferramentas Recomendadas

1. **Análise Estática**:
   - Credo: Para verificar estilo e boas práticas de código Elixir
   - Dialyxir: Para análise de tipos
   - ExDoc: Para geração de documentação

2. **Formatação de Código**:
   - mix format: Para manter o código formatado consistentemente

3. **Testes**:
   - ExUnit: Framework de testes padrão do Elixir
   - ExCoveralls: Para análise de cobertura de código

## Conclusão

Seguir estas diretrizes rigorosamente ajudará a manter a qualidade do código, minimizar erros e garantir que o projeto DeeperHub seja desenvolvido de acordo com as especificações. A revisão pós-implementação é **EXTREMAMENTE IMPORTANTE** e deve ser realizada após cada desenvolvimento ou correção para evitar a acumulação de problemas técnicos e garantir um código limpo e funcional.

Lembre-se: Um código limpo e bem estruturado é mais fácil de manter, estender e depurar. Invista tempo na qualidade agora para economizar tempo no futuro.

# Diretrizes de Correção de Erros de Compilação 🛠️

## 🚨 Regras Importantes de Compilação e Lint

### 1. Nomenclatura de Módulos 🏷️
⚠️ **IMPORTANTE**: 
- Todos os nomes de módulos devem seguir o padrão PascalCase
- Evite underscores em nomes de módulos
- Mantenha a hierarquia de pastas consistente com a nomenclatura dos módulos

### 2. Variáveis Não Utilizadas 🚫
⚠️ **IMPORTANTE**:
- Sempre adicione um underscore (`_`) antes de variáveis não utilizadas
- Exemplo: `{module, _function, _, _}` em pattern matching
- Remova variáveis completamente se não tiverem nenhum uso

### 3. Otimização de Operações com Enum 🔄
⚠️ **IMPORTANTE**:
- Prefira `Enum.map_join/3` em vez de `Enum.map/2 |> Enum.join/2`
- Isso melhora a performance e reduz a complexidade do código

### 4. Gerenciamento de Dependências 📦
⚠️ **IMPORTANTE**:
- Remova dependências não utilizadas do `mix.exs`
- Mantenha as versões das dependências atualizadas
- Documente o propósito de cada dependência

### 5. Tratamento de Warnings de Compilação 🚧
⚠️ **IMPORTANTE**:
- Trate todos os warnings como erros potenciais
- Corrija warnings assim que forem identificados
- Use ferramentas como Credo para análise estática

### 6. Documentação de Módulos e Funções 📝
⚠️ **IMPORTANTE**:
- Adicione `@moduledoc` para todos os módulos
- Use `@doc` para documentar funções públicas
- Inclua exemplos de uso quando possível

### 7. Especificações de Tipo 🔍
⚠️ **IMPORTANTE**:
- Adicione `@spec` para todas as funções públicas
- Garanta que as especificações de tipo estejam corretas
- Use tipos mais específicos possíveis

### 8. Gerenciamento de Aliases 🏷️
⚠️ **IMPORTANTE**:
- Mantenha aliases organizados alfabeticamente
- Remova aliases não utilizados
- Prefira aliases completos para evitar conflitos de nomenclatura

### 9. Tratamento de Erros 🛡️
⚠️ **IMPORTANTE**:
- Sempre trate possíveis erros e casos de falha
- Use pattern matching para tratamento de erros
- Evite usar `_` para ignorar completamente erros

### 10. Formatação de Código 🖌️
⚠️ **IMPORTANTE**:
- Use sempre `mix format` antes de commitar
- Mantenha a consistência de indentação
- Siga as convenções de estilo do Elixir

## Conclusão
Seguir estas diretrizes ajudará a manter a qualidade do código, reduzir bugs e melhorar a manutenibilidade do projeto DeeperHub.

**Lembre-se**: Um código limpo hoje economiza horas de depuração no futuro! 🚀

