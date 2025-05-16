project('deeper_client', 'cpp',
  version : '0.1.0',
  default_options : ['warning_level=3', 'cpp_std=c++17']
)

src_files = [
  'src/main.cpp'
]

incdir = include_directories('include')

# Dependências externas
dep_list = []

# Usar subprojetos para as dependências
json_dep = dependency('nlohmann_json', fallback: ['nlohmann_json', 'nlohmann_json_dep'])
websocketpp_dep = dependency('websocketpp', fallback: ['websocketpp', 'websocketpp_dep'], required: false)

# Adicionar dependências à lista
dep_list += json_dep

# Adicionar diretórios de inclusão para as bibliotecas externas
websocketpp_include = include_directories('subprojects/websocketpp-0.8.2')

# Adicionar diretório do Boost aos caminhos de inclusão
# Primeiro verificamos se o diretório external/boost existe
boost_dir = 'external/boost'
if run_command('cmd', '/c', 'if exist ' + boost_dir + ' echo true', check: false).stdout().strip() == 'true'
  boost_include = include_directories(boost_dir)
  incdir = [incdir, websocketpp_include, boost_include]
else
  # Se não existir, apenas adiciona o websocketpp
  incdir = [incdir, websocketpp_include]
  warning('Diretório do Boost não encontrado. Execute download_boost.bat para baixar o Boost.')  
endif

# Adicionar diretório do OpenSSL aos caminhos de inclusão
openssl_dir = 'external/openssl/include'
if run_command('cmd', '/c', 'if exist ' + openssl_dir + ' echo true', check: false).stdout().strip() == 'true'
  openssl_include = include_directories(openssl_dir)
  incdir = [incdir, openssl_include]
else
  warning('Diretório do OpenSSL não encontrado. Execute download_openssl.bat para baixar o OpenSSL.')
endif

executable('deeper_client',
  src_files,
  include_directories : incdir,
  dependencies : dep_list
)