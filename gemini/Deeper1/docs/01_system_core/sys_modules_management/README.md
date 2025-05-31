# Documentação Deeper: Gerenciamento de Módulos do Sistema

Este diretório detalha a API e a estrutura de dados para o gerenciamento e consulta de módulos do sistema UNA dentro da API \"Deeper\". A tabela `sys_modules` é o registro central de todos os módulos instalados, seu status e configurações básicas.

## Componentes:

1.  [**Migrações (`migrations/`)**](./migrations/README.md):
    *   Define a migração para criar a tabela `sys_modules`.

2.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md) (Ex: `Deeper.SystemCore.ModulesRepo`):
    *   Fornece funções para listar módulos, verificar se um módulo está habilitado, e obter configurações de um módulo específico.

3.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md) (Principalmente para Admin):
    *   Endpoints para listar módulos, habilitar/desabilitar (se a API \"Deeper\" for controlar isso), e obter informações de módulos.

## Importância:

A informação sobre os módulos ativos é crucial para:
*   Determinar quais funcionalidades da API devem estar disponíveis.
*   Saber quais prefixos de classe/tabela usar ao interagir com dados de módulos.
*   Carregar dinamicamente configurações ou serviços específicos de módulos.