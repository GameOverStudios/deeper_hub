import os
import mysql.connector
import re
from datetime import datetime, date

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

# Função para obter a chave primária de uma tabela
def obter_chave_primaria(conexao, tabela):
    cursor = conexao.cursor()
    cursor.execute(f"""
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = '{tabela}'
    AND CONSTRAINT_NAME = 'PRIMARY'
    ORDER BY ORDINAL_POSITION
    """)
    colunas_pk = [coluna[0] for coluna in cursor.fetchall()]
    return colunas_pk

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
    migrations_dir = os.path.join("../lib", "deeper_hub", "core", "data", "migrations")
    seeds_dir = os.path.join("../lib", "deeper_hub", "core", "data", "migrations", "seeds")
    schemas_dir = os.path.join("../lib", "deeper_hub", "core", "data", "schemas")
    resources_dir = os.path.join("../lib", "deeper_hub", "web_interface", "resources")
    router_dir = os.path.join("../lib", "deeper_hub", "web_interface")
    base_dir = os.path.join("../lib", "deeper_hub", "core", "data")
    web_base_dir = os.path.join("../lib", "deeper_hub", "web_interface")
    
    # Criar diretórios se não existirem
    for dir_path in [migrations_dir, seeds_dir, schemas_dir, resources_dir, router_dir, base_dir, web_base_dir]:
        if not os.path.exists(dir_path):
            os.makedirs(dir_path)
    
    # Limpar diretórios que precisam ser limpos
    for dir_path in [migrations_dir, schemas_dir, resources_dir]:
        if dir_path == migrations_dir:
            # Para migrations, preservar o diretório seeds
            for arquivo in os.listdir(dir_path):
                caminho_arquivo = os.path.join(dir_path, arquivo)
                if os.path.isfile(caminho_arquivo):
                    try:
                        os.unlink(caminho_arquivo)
                    except PermissionError:
                        print(f"Aviso: Não foi possível excluir {caminho_arquivo} - arquivo em uso")
        else:
            # Para outros diretórios, limpar tudo
            for arquivo in os.listdir(dir_path):
                caminho_arquivo = os.path.join(dir_path, arquivo)
                if os.path.isfile(caminho_arquivo):
                    try:
                        os.unlink(caminho_arquivo)
                    except PermissionError:
                        print(f"Aviso: Não foi possível excluir {caminho_arquivo} - arquivo em uso")
    
    # Limpar diretório seeds
    for arquivo in os.listdir(seeds_dir):
        caminho_arquivo = os.path.join(seeds_dir, arquivo)
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
    base_output_path = os.path.join("../lib", "deeper_hub", "core", "data", "schemas")
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
        print(f"    + {tabela} Schema")
    except PermissionError:
        print(f"Aviso: Não foi possível criar o schema para {tabela} - arquivo em uso ou sem permissão")

# Função para criar migration para uma tabela específica usando templates
def criar_migration(tabela, campos, relacoes=None, conexao=None):
    # Diretório para salvar as migrations
    base_output_path = os.path.join("../lib", "deeper_hub", "core", "data", "migrations")
    if not os.path.exists(base_output_path):
        os.makedirs(base_output_path)
    
    # Obter informações sobre a chave primária da tabela
    chaves_primarias = None
    if conexao:
        chaves_primarias = obter_chave_primaria(conexao, tabela)
        print(f"Chaves primárias para {tabela}: {chaves_primarias}")
    
    # Converter nome da tabela para formato de módulo Elixir (CamelCase)
    modulo_nome = ''.join(word.capitalize() for word in tabela.split('_'))
    
    # Caminho do arquivo de migration
    # Adicionando milissegundos ao timestamp para evitar nomes duplicados
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S%f")[:17]  # Pegando apenas os 3 primeiros dígitos dos milissegundos
    arquivo_path = os.path.join(base_output_path, f"{timestamp}_{tabela}.ex")
    
    # Gerar SQL para criar a tabela
    sql_create_table = gerar_create_table_sql(tabela, campos, relacoes, chaves_primarias)
    
    # Adicionar indentação correta para o heredoc em Elixir
    # Cada linha deve ter 4 espaços de indentação para alinhar com as aspas triplas de fechamento
    sql_indentado = "    " + sql_create_table.replace("\n", "\n    ")
    
    # Ler o template de migration
    template_path = "migration_template.md"
    template = ler_template(template_path)
    
    # Preparar as substituições
    substituicoes = {
        "MODULE_NAME": modulo_nome,
        "TABLE_NAME": tabela,
        "CREATE_TABLE_SQL": sql_indentado.replace("`", "")
    }
    
    # Substituir os placeholders
    conteudo = substituir_placeholders(template, substituicoes)
    
    try:
        with open(arquivo_path, 'w', encoding='utf-8') as arquivo:
            arquivo.write(conteudo)
        print(f"    + {tabela} Migration")
    except PermissionError:
        print(f"Aviso: Não foi possível criar a migration para {tabela} - arquivo em uso ou sem permissão")

# Função para gerar SQL para criar tabela
def gerar_create_table_sql(tabela, campos, relacoes=None, chaves_primarias=None):
    # Iniciar o SQL para criar a tabela
    sql = f"CREATE TABLE IF NOT EXISTS {tabela} (\n"
    
    # Adicionar colunas
    colunas = []
    for campo in campos:
        nome_campo = campo[0]
        tipo_campo = campo[1]
        nulo = "NULL" if campo[2] == "YES" else "NOT NULL"
        
        # Tratar valor padrão corretamente para SQLite
        padrao = ""
        if campo[4] is not None and campo[4] != "":
            # Remover aspas extras para valores numéricos
            if campo[4].isdigit() or (campo[4].startswith("-") and campo[4][1:].isdigit()):
                padrao = f"DEFAULT {campo[4]}"
            else:
                padrao = f"DEFAULT '{campo[4]}'"
        
        # Mapear tipos de dados MySQL para tipos compatíveis com SQLite
        if "int" in tipo_campo.lower():
            # Para id com auto_increment, usar INTEGER PRIMARY KEY AUTOINCREMENT
            if nome_campo == "id" and campo[5] and "auto_increment" in campo[5].lower():
                tipo_campo = "INTEGER"
                extra = "PRIMARY KEY AUTOINCREMENT"
            else:
                tipo_campo = "INTEGER"
                extra = ""
        elif "varchar" in tipo_campo.lower() or "text" in tipo_campo.lower():
            tipo_campo = "TEXT"
            extra = ""
        elif "date" in tipo_campo.lower() or "datetime" in tipo_campo.lower():
            tipo_campo = "TEXT"
            extra = ""
        elif "float" in tipo_campo.lower() or "double" in tipo_campo.lower() or "decimal" in tipo_campo.lower():
            tipo_campo = "REAL"
            extra = ""
        elif "bool" in tipo_campo.lower():
            tipo_campo = "INTEGER"
            extra = ""
        else:
            tipo_campo = "TEXT"
            extra = ""
        
        # Verificar se o nome da coluna é uma palavra reservada do SQLite
        palavras_reservadas = [
            "abort", "action", "add", "after", "all", "alter", "analyze", "and", "as", "asc",
            "attach", "autoincrement", "before", "begin", "between", "by", "cascade", "case", "cast",
            "check", "collate", "column", "commit", "conflict", "constraint", "create", "cross",
            "current", "current_date", "current_time", "current_timestamp", "database", "default",
            "deferrable", "deferred", "delete", "desc", "detach", "distinct", "drop", "each",
            "else", "end", "escape", "except", "exclusive", "exists", "explain", "fail", "for",
            "foreign", "from", "full", "glob", "group", "having", "if", "ignore", "immediate",
            "in", "index", "indexed", "initially", "inner", "insert", "instead", "intersect", "into",
            "is", "isnull", "join", "key", "left", "like", "limit", "match", "natural", "no", "not",
            "notnull", "null", "of", "offset", "on", "or", "order", "outer", "plan", "pragma",
            "primary", "query", "raise", "recursive", "references", "regexp", "reindex", "release",
            "rename", "replace", "restrict", "right", "rollback", "row", "savepoint", "select",
            "set", "table", "temp", "temporary", "then", "to", "transaction", "trigger", "type",
            "union", "unique", "update", "using", "vacuum", "values", "view", "virtual", "when",
            "where", "with", "without"
        ]
        
        # Se for palavra reservada, colocar entre aspas duplas
        if nome_campo.lower() in palavras_reservadas:
            nome_campo_formatado = f'"{nome_campo}"'
        else:
            nome_campo_formatado = nome_campo
            
        # Construir a definição da coluna
        coluna = f"  {nome_campo_formatado} {tipo_campo} {nulo} {padrao} {extra}".strip().replace("  ", " ")
        colunas.append(coluna)
    
    # Adicionar chave primária se não estiver nas colunas e não houver AUTOINCREMENT
    if not any(("PRIMARY KEY" in coluna) or ("AUTOINCREMENT" in coluna) for coluna in colunas):
        # Verificar se temos informações sobre a chave primária da tabela original
        if chaves_primarias and len(chaves_primarias) > 0:
            # Se for uma única coluna e for 'id', podemos usar AUTOINCREMENT
            if len(chaves_primarias) == 1 and chaves_primarias[0].lower() == 'id':
                # Substituir a coluna id existente
                for i, coluna in enumerate(colunas):
                    if coluna.strip().startswith("id "):
                        colunas[i] = "  id INTEGER PRIMARY KEY AUTOINCREMENT"
                        break
            else:
                # Se for uma chave composta ou não for 'id', adicionar como PRIMARY KEY
                # Verificar se os nomes das colunas precisam ser escapados (palavras reservadas)
                pk_colunas = []
                for pk_col in chaves_primarias:
                    if pk_col.lower() in palavras_reservadas:
                        pk_colunas.append(f'"{pk_col}"')
                    else:
                        pk_colunas.append(pk_col)
                
                # Adicionar a definição da chave primária
                colunas.append(f"  PRIMARY KEY ({', '.join(pk_colunas)})")
        else:
            # Sem informações da chave primária original, usar heurística
            # Verificar se existe coluna id
            if any(coluna.strip().startswith("id ") for coluna in colunas):
                # Substituir a coluna id existente
                for i, coluna in enumerate(colunas):
                    if coluna.strip().startswith("id "):
                        colunas[i] = "  id INTEGER PRIMARY KEY AUTOINCREMENT"
                        break
            else:
                # Procurar por uma coluna que possa ser a chave primária (normalmente termina com _id)
                id_column = None
                for coluna in colunas:
                    # Extrair o nome da coluna da definição
                    col_parts = coluna.strip().split(' ')
                    if len(col_parts) > 0:
                        col_name = col_parts[0].strip('"')
                        # Verificar se a coluna termina com _id ou é chamada de id
                        if col_name.endswith('_id') or col_name == 'id':
                            id_column = col_name
                            break
                
                # Se encontrou uma coluna de ID, usá-la como chave primária
                if id_column:
                    colunas.append(f"  PRIMARY KEY ({id_column})")
                else:
                    # Se não encontrou nenhuma coluna de ID, usar a primeira coluna como chave primária
                    if colunas:
                        first_col = colunas[0].strip().split(' ')[0].strip('"')
                        colunas.append(f"  PRIMARY KEY ({first_col})")
                    else:
                        # Caso extremo: não há colunas definidas
                        colunas.append("  PRIMARY KEY (id)")
                        print(f"AVISO: Tabela {tabela} não tem colunas de ID identificáveis. Usando 'id' como padrão.")
                        print("Isso pode causar erros se a coluna 'id' não existir na tabela.")
    
    # Adicionar chaves estrangeiras se existirem
    if relacoes:
        for relacao in relacoes:
            tabela_origem = relacao[0]
            coluna_origem = relacao[1]
            tabela_referencia = relacao[2]
            coluna_referencia = relacao[3]
            
            if tabela_origem == tabela:
                # SQLite usa uma sintaxe mais simples para chaves estrangeiras
                foreign_key = f"  FOREIGN KEY ({coluna_origem}) REFERENCES {tabela_referencia}({coluna_referencia})"
                colunas.append(foreign_key)
    
    # Finalizar o SQL
    sql += ",\n".join(colunas)
    sql += "\n);"
    
    return sql

# Função para criar resource para uma tabela específica usando templates
def criar_resource(tabela, campos, relacoes=None):
    # Diretório para salvar os resources
    base_output_path = os.path.join("../lib", "deeper_hub", "web_interface", "resources")
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
        print(f"    + {tabela} Resource")
    except PermissionError:
        print(f"Aviso: Não foi possível criar o resource para {tabela} - arquivo em uso ou sem permissão")

# Função para criar ou atualizar o router com as novas rotas
def criar_router(tabelas):
    # Diretório para salvar o router
    base_output_path = os.path.join("../lib", "deeper_hub", "web_interface")
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

# Função para gerar seeds das tabelas
def criar_seeds(conexao, tabela):
    print(f"Gerando seeds para a tabela: {tabela}")
    
    # Diretório para os seeds
    seeds_dir = os.path.join("../lib", "deeper_hub", "core", "data", "migrations", "seeds")
    
    # Verificar se a tabela tem dados
    cursor = conexao.cursor()
    cursor.execute(f"SELECT COUNT(*) FROM {tabela}")
    count = cursor.fetchone()[0]
    
    if count == 0:
        print(f"Tabela {tabela} não possui registros. Seed não gerado.")
        return
    
    # Obter dados da tabela
    cursor.execute(f"SELECT * FROM {tabela}")
    registros = cursor.fetchall()
    
    # Obter nomes das colunas
    cursor.execute(f"SHOW COLUMNS FROM {tabela}")
    colunas = [coluna[0] for coluna in cursor.fetchall()]
    
    # Nome do arquivo de seed
    nome_arquivo = f"seed_{tabela}.ex"
    caminho_arquivo = os.path.join(seeds_dir, nome_arquivo)
    
    # Gerar comandos de inserção
    inserts = []
    for registro in registros:
        # Criar mapa com os valores
        valores = {}
        for i, coluna in enumerate(colunas):
            valor = registro[i]
            
            # Formatar valor de acordo com o tipo
            if valor is None:
                valor_str = "nil"
            elif isinstance(valor, str):
                # Escapar aspas
                valor = valor.replace('"', '\\"')
                valor_str = f'"{valor}"'
            elif isinstance(valor, (int, float)):
                valor_str = str(valor)
            elif isinstance(valor, bytes):
                # Converter bytes para string hexadecimal
                valor_str = f'<<{valor.hex()}::binary>>'
            elif isinstance(valor, datetime):
                # Formatar datetime
                valor_str = f'~N"{valor.strftime("%Y-%m-%d %H:%M:%S")}"'
            elif isinstance(valor, date):
                # Formatar date
                valor_str = f'~D"{valor.strftime("%Y-%m-%d")}"'
            else:
                # Outros tipos
                valor_str = f'"{str(valor)}"'
            
            valores[coluna] = valor_str
        
        # Criar comando de inserção
        # Escapar aspas nos nomes das colunas para SQL
        campos_str = ", ".join([campo for campo in valores.keys()])
        valores_str = ", ".join([valores[campo] for campo in valores.keys()])
        placeholders = ', '.join(['?' for _ in valores])
        
        insert = f"    Repo.execute(\"INSERT INTO {tabela} ({campos_str}) VALUES ({placeholders})\", [{valores_str}])"
        inserts.append(insert)
    
    # Juntar todos os inserts
    inserts_str = "\n".join(inserts)
    
    # Ler template de seed
    template = ler_template("seed_template.md")
    
    # Substituir placeholders
    # Converter nome da tabela para formato de módulo Elixir (CamelCase)
    modulo_nome = ''.join(word.capitalize() for word in tabela.split('_'))
    substituicoes = {
        "MODULE_NAME": modulo_nome,
        "TABLE_NAME": tabela,
        "SEED_INSERTS": inserts_str
    }
    
    conteudo = substituir_placeholders(template, substituicoes)
    
    # Criar arquivo de seed
    try:
        with open(caminho_arquivo, 'w', encoding='utf-8') as arquivo:
            arquivo.write(conteudo)
        
        print(f"    + {tabela} Seeds")
    except Exception as e:
        print(f"Erro ao gerar seed para a tabela {tabela}: {str(e)}")

# Função para atualizar o registro de migrações
def atualizar_registro_migracoes(tabelas_com_seed=[]):
    # Diretório das migrações
    migrations_dir = os.path.join("../lib", "deeper_hub", "core", "data", "migrations")
    if not os.path.exists(migrations_dir):
        os.makedirs(migrations_dir)
    
    # Caminho do arquivo de registro
    registry_path = os.path.join(migrations_dir, "migration_registry.ex")
    
    # Encontrar todos os arquivos de migração
    migrations = []
    for arquivo in os.listdir(migrations_dir):
        # Verificar se é um arquivo de migração (formato: timestamp_nome_tabela.ex)
        if arquivo.endswith(".ex") and "_" in arquivo and not arquivo.startswith("migration_registry"):
            try:
                # Extrair timestamp e nome da tabela
                partes = arquivo.replace(".ex", "").split("_", 1)
                if len(partes) == 2 and partes[0].isdigit():
                    timestamp = partes[0]
                    nome_tabela = partes[1]
                    
                    # Converter nome da tabela para formato de módulo Elixir (CamelCase)
                    modulo_nome = ''.join(word.capitalize() for word in nome_tabela.split('_'))
                    modulo_completo = f"DeeperHub.Core.Data.Migrations.{modulo_nome}"
                    
                    migrations.append((timestamp, modulo_completo))
            except Exception as e:
                print(f"Erro ao processar arquivo de migração {arquivo}: {str(e)}")
    
    # Ordenar migrações por timestamp
    migrations.sort(key=lambda x: x[0])
    
    # Gerar conteúdo do arquivo de registro
    conteudo = """defmodule DeeperHub.Core.Data.Migrations.MigrationRegistry do
  @moduledoc \"\"\"
  Registro centralizado de migrações disponíveis no sistema.
  Este módulo é gerado e atualizado automaticamente pelo gerador.
  \"\"\" 

  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc \"\"\" 
  Retorna a lista de migrações disponíveis no sistema.
  Cada migração é representada por uma tupla {versão, módulo}.
  \"\"\" 
  def available_migrations do
    [
"""
    
    # Adicionar cada migração
    for timestamp, modulo in migrations:
        conteudo += f"      {{\"{timestamp}\", {modulo}}},\n"
    
    # Fechar a lista de migrações
    conteudo += "    ]\n  end\n\n"
    
    # Adicionar função para executar seeds
    conteudo += "  @doc \"\"\"\n  Retorna a lista de seeds disponíveis no sistema.\n  \"\"\"\n  def available_seeds do\n    [\n"
    
    # Adicionar cada seed
    for tabela in tabelas_com_seed:
        # Converter nome da tabela para formato de módulo Elixir (CamelCase)
        modulo_nome = ''.join(word.capitalize() for word in tabela.split('_'))
        modulo_completo = f"DeeperHub.Core.Data.Migrations.Seeds.{modulo_nome}Seed"
        
        conteudo += f"      {modulo_completo},\n"
    
    # Fechar o módulo
    conteudo += "    ]\n  end\n\n"
    
    # Adicionar função para executar seeds
    conteudo += ("""
  @doc \"\"\"
  Executa todos os seeds disponíveis.
  \"\"\"
  def run_seeds do
    Logger.info(\"Executando seeds...\", module: __MODULE__)
    
    Enum.each(available_seeds(), fn seed_module ->
      Logger.info(\"Executando seed: #{inspect(seed_module)}\", module: __MODULE__)
      seed_module.run()
    end)
    
    Logger.info(\"Seeds executados com sucesso.\", module: __MODULE__)
    :ok
  end
end
""")
    
    # Escrever o arquivo de registro
    try:
        with open(registry_path, 'w', encoding='utf-8') as arquivo:
            arquivo.write(conteudo)
        print("Registro de migrações e seeds atualizado com sucesso.")
    except Exception as e:
        print(f"Erro ao atualizar registro de migrações e seeds: {str(e)}")

# Função para criar o gerenciador de seeds
def criar_seed_manager(tabelas_com_seed):
    print("Gerando gerenciador de seeds...")
    
    # Diretório para os seeds
    seeds_dir = os.path.join("../lib", "deeper_hub", "core", "data", "migrations", "seeds")
    if not os.path.exists(seeds_dir):
        os.makedirs(seeds_dir)
    
    # Nome do arquivo do gerenciador
    nome_arquivo = "seed_manager.ex"
    caminho_arquivo = os.path.join(seeds_dir, nome_arquivo)
    
    # Gerar lista de módulos de seed
    modulos_seed = []
    for tabela in tabelas_com_seed:
        # Converter nome da tabela para formato de módulo Elixir (CamelCase)
        modulo_nome = ''.join(word.capitalize() for word in tabela.split('_'))
        modulo = f"DeeperHub.Core.Data.Migrations.Seeds.{modulo_nome}Seed"
        modulos_seed.append(modulo)
    
    # Formatar a lista de módulos para o template
    modulos_str = ",\n      ".join(modulos_seed)
    
    # Ler template do gerenciador de seeds
    template = ler_template("seed_manager_template.md")
    
    # Substituir placeholders
    substituicoes = {
        "SEED_MODULES": modulos_str
    }
    
    conteudo = substituir_placeholders(template, substituicoes)
    
    # Criar arquivo do gerenciador de seeds
    try:
        with open(caminho_arquivo, 'w', encoding='utf-8') as arquivo:
            arquivo.write(conteudo)
        
        print("Gerenciador de seeds gerado com sucesso.")
    except Exception as e:
        print(f"Erro ao gerar gerenciador de seeds: {str(e)}")

# Função principal
if __name__ == "__main__":
    import argparse
    
    # Configurar o parser de argumentos
    parser = argparse.ArgumentParser(description='Gerador de código para DeeperHub')
    parser.add_argument('--table', type=str, help='Nome da tabela específica para gerar código (opcional)')
    args = parser.parse_args()
    
    # Conectar ao MySQL
    try:
        conexao = conectar_mysql()
        print("Conexão com MySQL estabelecida com sucesso.")
        
        # Limpar diretórios
        limpar_diretorios()
        print("Diretórios limpos com sucesso.")
        
        # Obter tabelas
        all_tabelas = obter_tabelas(conexao)
        
        # Filtrar tabelas se um nome específico foi fornecido
        if args.table:
            tabela_especifica = args.table.lower()
            tabelas = [tabela for tabela in all_tabelas if tabela.lower() == tabela_especifica]
            if not tabelas:
                print(f"Erro: Tabela '{args.table}' não encontrada no banco de dados.")
                exit(1)
            print(f"Gerando código apenas para a tabela: {tabelas[0]}")
        else:
            tabelas = all_tabelas
            print(f"Tabelas encontradas: {', '.join(tabelas)}")
        
        # Obter relações
        relacoes = obter_relacoes(conexao)
        
        # Lista para armazenar tabelas que têm seeds
        tabelas_com_seed = []
        
        # Processar cada tabela individualmente (criar migration, schema, resource e seed)
        for tabela in tabelas:
            campos = obter_campos(conexao, tabela)
            print(f"Processando tabela: {tabela}")
            
            # Criar migration
            criar_migration(tabela, campos, relacoes, conexao)
            
            # Criar schema para esta tabela
            criar_schema(tabela, campos, relacoes)
            
            # Criar resource para esta tabela
            criar_resource(tabela, campos, relacoes)
            
            # Verificar se a tabela tem dados para seed
            cursor = conexao.cursor()
            cursor.execute(f"SELECT COUNT(*) FROM {tabela}")
            count = cursor.fetchone()[0]
            
            # Criar seed para esta tabela (se tiver dados)
            #if count > 0:
                #criar_seeds(conexao, tabela)
                #tabelas_com_seed.append(tabela)
            
            print(f"    + {tabela} [OK]")
        
        # Atualizar o registro de migrações após criar todas as migrações
        atualizar_registro_migracoes(tabelas_com_seed)
        
        # Criar router com todas as tabelas se não estiver gerando para uma tabela específica
        # Se estiver gerando para uma tabela específica, obter todas as tabelas para o router
        if args.table:
            # Para o router, precisamos de todas as tabelas existentes
            # Verificar se já existem arquivos de resource para outras tabelas
            resources_dir = os.path.join("../lib", "deeper_hub", "web_interface", "resources")
            existing_resources = [f.replace("_resource.ex", "") for f in os.listdir(resources_dir) 
                                if f.endswith("_resource.ex") and os.path.isfile(os.path.join(resources_dir, f))]
            
            # Adicionar a tabela específica se não estiver na lista
            if tabelas[0] not in existing_resources:
                existing_resources.append(tabelas[0])
                
            criar_router(existing_resources)
        else:
            criar_router(tabelas)
        
        # Criar gerenciador de seeds se houver tabelas com seed
        if tabelas_com_seed:
            # Se estiver gerando para uma tabela específica, verificar seeds existentes
            if args.table:
                seeds_dir = os.path.join("../lib", "deeper_hub", "core", "data", "migrations", "seeds")
                existing_seeds = [f.replace("seed_", "").replace(".ex", "") for f in os.listdir(seeds_dir) 
                                if f.startswith("seed_") and f != "seed_manager.ex" and os.path.isfile(os.path.join(seeds_dir, f))]
                
                # Adicionar as tabelas com seed que não estão na lista
                for tabela in tabelas_com_seed:
                    if tabela not in existing_seeds:
                        existing_seeds.append(tabela)
                        
                criar_seed_manager(existing_seeds)
            else:
                criar_seed_manager(tabelas_com_seed)
        
        print("Processo concluído com sucesso!")
        
    except mysql.connector.Error as err:
        print(f"Erro ao conectar ao MySQL: {err}")
    finally:
        if 'conexao' in locals() and conexao.is_connected():
            conexao.close()
            print("Conexão com MySQL encerrada.")
