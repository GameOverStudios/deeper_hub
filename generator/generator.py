import os
import shutil
import mysql.connector
from datetime import datetime
import re

# Função para conectar ao MySQL
def conectar_mysql(host='localhost', usuario='root', senha='', banco='una'):
    conexao = mysql.connector.connect(
        host=host,
        user=usuario,
        password=senha,
        database=banco
    )
    return conexao

# Função para obter informações das tabelas
def obter_tabelas(conexao):
    cursor = conexao.cursor()
    cursor.execute("SHOW TABLES")
    tabelas = [tabela[0] for tabela in cursor.fetchall()]
    return tabelas

# Função para obter informações dos campos de uma tabela
def obter_campos(conexao, tabela):
    cursor = conexao.cursor()
    cursor.execute(f"DESCRIBE {tabela}")
    campos = cursor.fetchall()
    return campos

# Função para obter informações das relações entre tabelas (chaves estrangeiras)
def obter_relacoes(conexao):
    cursor = conexao.cursor()
    cursor.execute("""
    SELECT 
        TABLE_NAME, 
        COLUMN_NAME, 
        REFERENCED_TABLE_NAME, 
        REFERENCED_COLUMN_NAME 
    FROM 
        INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE 
        REFERENCED_TABLE_SCHEMA = DATABASE() 
        AND REFERENCED_TABLE_NAME IS NOT NULL
    """)
    relacoes = cursor.fetchall()
    return relacoes

# Função para limpar diretórios de migrations e schemas
def limpar_diretorios():
    # Cria diretórios se não existirem
    migrations_dir = os.path.join("lib", "deeper_hub", "core", "data", "migrations")
    schemas_dir = os.path.join("lib", "deeper_hub", "core", "data", "schemas")
    resources_dir = os.path.join("lib", "deeper_hub", "web_interface", "resources")
    router_dir = os.path.join("lib", "deeper_hub", "web_interface")
    base_dir = os.path.join("lib", "deeper_hub", "core", "data")
    web_base_dir = os.path.join("lib", "deeper_hub", "web_interface")
    
    # Criar diretórios se não existirem
    for dir_path in [migrations_dir, schemas_dir, resources_dir, router_dir, base_dir, web_base_dir]:
        if not os.path.exists(dir_path):
            os.makedirs(dir_path)
    
    # Limpar diretórios que precisam ser limpos
    for dir_path in [migrations_dir, schemas_dir, resources_dir]:
        for arquivo in os.listdir(dir_path):
            caminho_arquivo = os.path.join(dir_path, arquivo)
            if os.path.isfile(caminho_arquivo):
                try:
                    os.unlink(caminho_arquivo)
                except PermissionError:
                    print(f"Aviso: Não foi possível excluir {caminho_arquivo} - arquivo em uso")

# Função para ler o conteúdo de um arquivo de template
def ler_template(caminho_template):
    with open(caminho_template, 'r', encoding='utf-8') as arquivo:
        return arquivo.read()

# Função para substituir placeholders em um template
def substituir_placeholders(template, substituicoes):
    for chave, valor in substituicoes.items():
        template = template.replace(f"{{{{{chave}}}}}", valor)
    return template

# Função para criar schemas usando templates
def criar_schema(tabela, campos, relacoes=None):
    # Diretório para salvar os schemas
    base_output_path = os.path.join("lib", "deeper_hub", "core", "data", "schemas")
    if not os.path.exists(base_output_path):
        os.makedirs(base_output_path)
    
    # Converter nome da tabela para formato de módulo Elixir (CamelCase)
    modulo_nome = ''.join(word.capitalize() for word in tabela.split('_'))
    
    # Converter para singular (regra simples, pode precisar de ajustes)
    nome_singular = tabela
    if nome_singular.endswith('s'):
        nome_singular = nome_singular[:-1]
    
    # Caminho do arquivo de schema
    arquivo_path = os.path.join(base_output_path, f"{tabela}.ex")
    
    # Ler o template de schema
    template_path = "schema_template.md"
    template = ler_template(template_path)
    
    # Preparar as substituições
    substituicoes = {
        "MODULE_NAME": modulo_nome,
        "TABLE_NAME": tabela,
        "SINGULAR_NAME": nome_singular
    }
    
    # Substituir os placeholders
    conteudo = substituir_placeholders(template, substituicoes)
    
    try:
        with open(arquivo_path, 'w', encoding='utf-8') as arquivo:
            arquivo.write(conteudo)
        print(f"Schema para tabela {tabela} criado com sucesso.")
    except PermissionError:
        print(f"Aviso: Não foi possível criar o schema para {tabela} - arquivo em uso ou sem permissão")

# Função para criar migration para uma tabela específica usando templates
def criar_migration(tabela, campos, relacoes=None):
    # Diretório para salvar as migrations
    base_output_path = os.path.join("lib", "deeper_hub", "core", "data", "migrations")
    if not os.path.exists(base_output_path):
        os.makedirs(base_output_path)
    
    # Converter nome da tabela para formato de módulo Elixir (CamelCase)
    modulo_nome = ''.join(word.capitalize() for word in tabela.split('_'))
    
    # Caminho do arquivo de migration
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    arquivo_path = os.path.join(base_output_path, f"{timestamp}_{tabela}.ex")
    
    # Gerar SQL para criar a tabela
    create_table_sql = gerar_create_table_sql(tabela, campos, relacoes)
    
    # Ler o template de migration
    template_path = "migration_template.md"
    template = ler_template(template_path)
    
    # Preparar as substituições
    substituicoes = {
        "MODULE_NAME": modulo_nome,
        "TABLE_NAME": tabela,
        "CREATE_TABLE_SQL": create_table_sql.replace("`", "")
    }
    
    # Substituir os placeholders
    conteudo = substituir_placeholders(template, substituicoes)
    
    try:
        with open(arquivo_path, 'w', encoding='utf-8') as arquivo:
            arquivo.write(conteudo)
        print(f"Migration para tabela {tabela} criada com sucesso.")
    except PermissionError:
        print(f"Aviso: Não foi possível criar a migration para {tabela} - arquivo em uso ou sem permissão")

# Função para gerar SQL para criar tabela
def gerar_create_table_sql(tabela, campos, relacoes=None):
    # Iniciar o SQL para criar a tabela
    sql = f"CREATE TABLE IF NOT EXISTS {tabela} (\n"
    
    # Adicionar colunas
    colunas = []
    for campo in campos:
        nome_campo = campo[0]
        tipo_campo = campo[1]
        nulo = "NULL" if campo[2] == "YES" else "NOT NULL"
        padrao = f"DEFAULT {campo[4]}" if campo[4] is not None else ""
        extra = campo[5] if campo[5] else ""
        
        # Mapear tipos de dados MySQL para tipos mais apropriados para Elixir
        if "int" in tipo_campo.lower():
            tipo_elixir = "integer"
        elif "varchar" in tipo_campo.lower() or "text" in tipo_campo.lower():
            tipo_elixir = "string"
        elif "date" in tipo_campo.lower() or "time" in tipo_campo.lower():
            tipo_elixir = "datetime"
        elif "decimal" in tipo_campo.lower() or "float" in tipo_campo.lower() or "double" in tipo_campo.lower():
            tipo_elixir = "float"
        elif "bool" in tipo_campo.lower():
            tipo_elixir = "boolean"
        else:
            tipo_elixir = "string"  # Padrão para tipos desconhecidos
        
        coluna = f"  {nome_campo} {tipo_campo} {nulo} {padrao} {extra}".strip()
        colunas.append(coluna)
    
    # Adicionar chave primária
    for campo in campos:
        if campo[3] == "PRI":
            colunas.append(f"  PRIMARY KEY ({campo[0]})")
    
    # Adicionar chaves estrangeiras se houver relações
    if relacoes:
        for relacao in relacoes:
            tabela_origem = relacao[0]
            coluna_origem = relacao[1]
            tabela_referencia = relacao[2]
            coluna_referencia = relacao[3]
            
            if tabela_origem == tabela:
                constraint_name = f"fk_{tabela}_{coluna_origem}"
                foreign_key = f"  CONSTRAINT {constraint_name} FOREIGN KEY ({coluna_origem}) REFERENCES {tabela_referencia}({coluna_referencia})"
                colunas.append(foreign_key)
    
    # Finalizar o SQL
    sql += ",\n".join(colunas)
    sql += "\n);"
    
    return sql

# Função para criar resource para uma tabela específica usando templates
def criar_resource(tabela, campos, relacoes=None):
    # Diretório para salvar os resources
    base_output_path = os.path.join("lib", "deeper_hub", "web_interface", "resources")
    if not os.path.exists(base_output_path):
        os.makedirs(base_output_path)
    
    # Converter nome da tabela para formato de módulo Elixir (CamelCase)
    modulo_nome = ''.join(word.capitalize() for word in tabela.split('_'))
    resource_name = modulo_nome
    
    # Converter para singular (regra simples, pode precisar de ajustes)
    nome_singular = tabela
    if nome_singular.endswith('s'):
        nome_singular = nome_singular[:-1]
    
    # Caminho do arquivo de resource
    arquivo_path = os.path.join(base_output_path, f"{tabela}_resource.ex")
    
    # Ler o template de resource
    template_path = "resource_template.md"
    template = ler_template(template_path)
    
    # Preparar as substituições
    substituicoes = {
        "RESOURCE_NAME": resource_name,
        "MODULE_NAME": modulo_nome,
        "TABLE_NAME": tabela,
        "SINGULAR_NAME": nome_singular
    }
    
    # Substituir os placeholders
    conteudo = substituir_placeholders(template, substituicoes)
    
    try:
        with open(arquivo_path, 'w', encoding='utf-8') as arquivo:
            arquivo.write(conteudo)
        print(f"Resource para tabela {tabela} criado com sucesso.")
    except PermissionError:
        print(f"Aviso: Não foi possível criar o resource para {tabela} - arquivo em uso ou sem permissão")

# Função para criar ou atualizar o router com as novas rotas
def criar_router(tabelas):
    # Diretório para salvar o router
    base_output_path = os.path.join("lib", "deeper_hub", "web_interface")
    if not os.path.exists(base_output_path):
        os.makedirs(base_output_path)
    
    # Caminho do arquivo de router
    arquivo_path = os.path.join(base_output_path, "router.ex")
    
    # Gerar rotas para todas as tabelas
    rotas = []
    for tabela in tabelas:
        modulo_nome = ''.join(word.capitalize() for word in tabela.split('_'))
        rota = f'forward("/api/{tabela}", to: DeeperHub.WebInterface.Resources.{modulo_nome}Resource)'
        rotas.append(rota)
    
    # Adicionar rotas padrão
    rotas.extend([
        'forward("/api/status", to: DeeperHub.WebInterface.Resources.StatusResource)',
        'forward("/api/info", to: DeeperHub.WebInterface.Resources.ServerInfoResource)',
        'forward("/api/routes", to: DeeperHub.WebInterface.Resources.RoutesResource)'
    ])
    
    # Ler o template de router
    template_path = "router_template.md"
    template = ler_template(template_path)
    
    # Preparar as substituições
    substituicoes = {
        "API_ROUTES": "\n  ".join(rotas)
    }
    
    # Substituir os placeholders
    conteudo = substituir_placeholders(template, substituicoes)
    
    try:
        with open(arquivo_path, 'w', encoding='utf-8') as arquivo:
            arquivo.write(conteudo)
        print(f"Router criado com sucesso.")
    except PermissionError:
        print(f"Aviso: Não foi possível criar o router - arquivo em uso ou sem permissão")

# Função para criar os módulos base
def criar_modulos_base():
    print("Criando módulos base...")
    
    # Diretórios para os módulos base
    schema_base_dir = os.path.join("lib", "deeper_hub", "core", "data")
    resource_base_dir = os.path.join("lib", "deeper_hub", "web_interface")
    
    # Criar diretórios se não existirem
    for dir_path in [schema_base_dir, resource_base_dir]:
        if not os.path.exists(dir_path):
            os.makedirs(dir_path)
    
    # Caminho dos arquivos de módulos base
    schema_base_path = os.path.join(schema_base_dir, "schema_base.ex")
    resource_base_path = os.path.join(resource_base_dir, "resource_base.ex")
    
    # Ler templates de módulos base
    schema_base_template = ler_template("schema_base_template.md")
    resource_base_template = ler_template("resource_base_template.md")
    
    # Criar arquivo SchemaBase
    try:
        with open(schema_base_path, 'w', encoding='utf-8') as arquivo:
            arquivo.write(schema_base_template)
        print("Módulo SchemaBase criado com sucesso.")
    except PermissionError:
        print(f"Aviso: Não foi possível criar o módulo SchemaBase - arquivo em uso ou sem permissão")
    
    # Criar arquivo ResourceBase
    try:
        with open(resource_base_path, 'w', encoding='utf-8') as arquivo:
            arquivo.write(resource_base_template)
        print("Módulo ResourceBase criado com sucesso.")
    except PermissionError:
        print(f"Aviso: Não foi possível criar o módulo ResourceBase - arquivo em uso ou sem permissão")

# Função principal
if __name__ == "__main__":
    # Conectar ao MySQL
    try:
        conexao = conectar_mysql()
        print("Conexão com MySQL estabelecida com sucesso.")
        
        # Limpar diretórios
        limpar_diretorios()
        print("Diretórios limpos com sucesso.")
        
        # Criar módulos base
        criar_modulos_base()
        
        # Obter tabelas
        tabelas = obter_tabelas(conexao)
        print(f"Tabelas encontradas: {', '.join(tabelas)}")
        
        # Obter relações
        relacoes = obter_relacoes(conexao)
        
        # Processar cada tabela individualmente (criar migration, schema e resource)
        for tabela in tabelas:
            campos = obter_campos(conexao, tabela)
            print(f"Processando tabela: {tabela}")
            
            # Criar migration para esta tabela
            criar_migration(tabela, campos, relacoes)
            
            # Criar schema para esta tabela
            criar_schema(tabela, campos, relacoes)
            
            # Criar resource para esta tabela
            criar_resource(tabela, campos, relacoes)
            
            print(f"Tabela {tabela} processada com sucesso.")
        
        # Criar router com todas as tabelas
        criar_router(tabelas)
        
        print("Processo concluído com sucesso!")
        
    except mysql.connector.Error as err:
        print(f"Erro ao conectar ao MySQL: {err}")
    finally:
        if 'conexao' in locals() and conexao.is_connected():
            conexao.close()
            print("Conexão com MySQL encerrada.")
