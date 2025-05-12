import os
import shutil
import re

PROJECT_ROOT = "DeeperHub_Project_Categorized_V4_1" # Nova versão
EXISTING_READMES_DIR = r"c:\New\readmes"

all_readme_files_in_source_dir = set()
used_readme_files_from_source = set()
placeholder_readmes_created = set()

# Mapeamento de chaves da estrutura para nomes de módulo Elixir esperados (para buscar READMEs)
# Usado para diretórios de primeiro nível ou contextos principais.
# Chave: nome da chave no dicionário CATEGORIZED_STRUCTURE (PascalCase como será o diretório)
# Valor: como ele deve ser formatado para buscar o README (sem DeeperHub_ no início, o script adiciona)
CONTEXT_README_MAPPING = {
    "Application": "Application",
    "Core": "Core",
    "Accounts": "Accounts",
    "Authentication": "Authentication",
    "Security": "Security",
    "Communication": "Communication",
    "Domain": "Domain",
    "APIGateway": "API", # Mapeia APIGateway para DeeperHub_API.md
    "Console": "Console",
    "DevTools": "DevTools",
    "Shared": "Shared",
    "Gamification": "Gamification", # Dentro de Domain
    # Adicione outros contextos de primeiro nível aqui se necessário
}


# Mapeamento de nomes de módulos da nova estrutura para nomes de arquivos README existentes
# Chave: Nome do módulo Elixir completo (ex: "DeeperHub.Core.CircuitBreakerFactory")
# Valor: Nome do arquivo .md na pasta EXISTING_READMES_DIR
EXPLICIT_README_MAPPING = {
    "DeeperHub.Core.CircuitBreakerFactory": "DeeperHub_Core_CircuitBreaker.md",
    "DeeperHub.Core.Repo": "DeeperHub_Core_Repo.md",
    "DeeperHub.Security.DeviceManagement": "DeeperHub_Security_DeviceFingerprint.md", # Ou DeviceService.md
    "DeeperHub.Security.GeoLocation": "DeeperHub_Security_GeoLocationService.md",
    "DeeperHub.Security.IPFirewall": "DeeperHub_Security_IPFirewallService.md",
    "DeeperHub.Security.PolicyManager": "DeeperHub_Security_Policy_SecurityPolicyManager.md",
    "DeeperHub.Security.SecurityMonitoring": "DeeperHub_Security_Monitoring.md", # Assumindo que existe
    "DeeperHub.DevTools.ModuleInspector": "DeeperHub_ModuleInspector.md",
    "DeeperHub.Shared.Utils": "DeeperHub_Shared_Utils.md",
    "DeeperHub.Core.GeoIP": "DeeperHub_GeoIP.md", # Se GeoIP está em Core e tem seu README
    "DeeperHub.Audit": "DeeperHub_Audit.md",
    "DeeperHub.Biometrics": "DeeperHub_Biometrics.md",
    "DeeperHub.FeatureFlags": "DeeperHub_FeatureFlags.md",

    # Mapeamentos para módulos de Authentication
    "DeeperHub.Authentication.Auth": "DeeperHub_Auth.md",
    "DeeperHub.Authentication.MFA": "DeeperHub_MFA.md",
    "DeeperHub.Authentication.OAuth": "DeeperHub_OAuth.md",
    "DeeperHub.Authentication.WebAuthn": "DeeperHub_WebAuthn.md",
    "DeeperHub.Authentication.Tokens": "DeeperHub_Tokens.md", # Se você tiver um DeeperHub_Tokens.md
    # "DeeperHub.Authentication.RBAC": "DeeperHub_RBAC.md", # Adicionar se tiver
    # "DeeperHub.Authentication.SecurityQuestions": "DeeperHub_SecurityQuestions.md", # Adicionar se tiver
    # "DeeperHub.Authentication.SessionPolicy": "DeeperHub_SessionPolicy.md", # Adicionar se tiver
    # "DeeperHub.Authentication.TemporaryPassword": "DeeperHub_TemporaryPassword.md", # Adicionar se tiver
    # "DeeperHub.Authentication.Recovery": "DeeperHub_Recovery.md", # Adicionar se tiver

    # Mapeamentos para módulos de Communication
    "DeeperHub.Communication.Notifications": "DeeperHub_Notifications.md",
    "DeeperHub.Communication.Mailer": "DeeperHub_Mailer.md",
    "DeeperHub.Communication.Webhooks": "DeeperHub_Webhooks.md",

    # Mapeamentos para módulos de Domain
    "DeeperHub.Domain.Servers": "DeeperHub_Servers.md",
    "DeeperHub.Domain.ServerAdvertisements": "DeeperHub_ServerAdvertisements.md",
    "DeeperHub.Domain.ServerAlerts": "DeeperHub_ServerAlerts.md",
    "DeeperHub.Domain.ServerEvents": "DeeperHub_ServerEvents.md",
    "DeeperHub.Domain.ServerPackages": "DeeperHub_ServerPackages.md",
    "DeeperHub.Domain.ServerReviews": "DeeperHub_ServerReviews.md",
    "DeeperHub.Domain.ServerTags": "DeeperHub_ServerTags.md",
    "DeeperHub.Domain.ServerUpdateMessages": "DeeperHub_ServerUpdateMessages.md",
    "DeeperHub.Domain.Gamification.Achievements": "DeeperHub_Achievements.md",
    "DeeperHub.Domain.Gamification.Challenges": "DeeperHub_Challenges.md",
    "DeeperHub.Domain.Gamification.Rewards": "DeeperHub_Rewards.md",
    "DeeperHub.Domain.Support": "DeeperHub_Support.md",
    "DeeperHub.Domain.UserInteractions": "DeeperHub_UserInteractions.md",
    "DeeperHub.Domain.Lists": "DeeperHub_Lists.md",
    # "DeeperHub.Domain.Search": "DeeperHub_Search.md", # Adicionar se tiver
}


def to_pascal_case(text):
    if not text: return ""
    if text.isupper() or (text[0].isupper() and any(c.islower() for c in text[1:])): return text
    text = text.replace(".", "_")
    return "".join(word.capitalize() for word in re.split('_|-', text))

def to_snake_case(name):
    name = re.sub(r'(?<!^)(?=[A-Z])', '_', name).lower()
    return name

def get_elixir_module_name(is_lib_deeper_hub_context, elixir_module_prefix_parts, file_or_dir_pascal_name):
    parts = []
    if is_lib_deeper_hub_context:
        parts.append("DeeperHub")

    parts.extend(elixir_module_prefix_parts)

    if not parts or parts[-1] != file_or_dir_pascal_name:
        parts.append(file_or_dir_pascal_name)

    cleaned_parts = []
    last_part = None
    for part in parts:
        if part != last_part:
            cleaned_parts.append(part)
        last_part = part
    return ".".join(cleaned_parts)


def find_existing_readme_content(elixir_module_name_for_lookup):
    global used_readme_files_from_source

    # 1. Tenta Mapeamento Explícito
    if elixir_module_name_for_lookup in EXPLICIT_README_MAPPING:
        fname = EXPLICIT_README_MAPPING[elixir_module_name_for_lookup]
        path_to_readme = os.path.join(EXISTING_READMES_DIR, fname)
        if os.path.exists(path_to_readme):
            try:
                with open(path_to_readme, "r", encoding="utf-8") as f_readme:
                    content = f_readme.read()
                used_readme_files_from_source.add(fname)
                # print(f"DEBUG: README ENCONTRADO (Explícito) '{fname}' para módulo '{elixir_module_name_for_lookup}'")
                return content
            except Exception as e:
                print(f"AVISO: Erro ao ler README (Explícito) {path_to_readme}: {e}")
                return f"Erro ao ler README: {path_to_readme}"
        # else:
            # print(f"DEBUG: README MAPEADO MAS NÃO ENCONTRADO (Explícito) '{fname}' para módulo '{elixir_module_name_for_lookup}'")

    # 2. Lógica de busca genérica
    # DeeperHub.Core.ConfigManager -> DeeperHub_Core_ConfigManager
    base_name_for_file = elixir_module_name_for_lookup.replace("DeeperHub.", "DeeperHub_").replace(".", "_")
    # DeeperHub.Core.ConfigManager -> ConfigManager
    short_name_for_file = elixir_module_name_for_lookup.split(".")[-1] # O nome do módulo em si

    potential_filenames = [
        f"Elixir_{base_name_for_file}.md",
        f"{base_name_for_file}.md",
        f"Elixir_DeeperHub_{short_name_for_file}.md",
        f"DeeperHub_{short_name_for_file}.md"
    ]
    if base_name_for_file.startswith("DeeperHub_"):
        potential_filenames.append(f"{base_name_for_file}.md") # Ex: DeeperHub_Core_ConfigManager.md

    # Para módulos de utils
    if elixir_module_name_for_lookup.startswith("DeeperHub.Shared.Utils."):
        util_name = short_name_for_file
        potential_filenames.insert(0, f"DeeperHub_Shared_Utils_{util_name}.md")

    for fname in potential_filenames:
        path_to_readme = os.path.join(EXISTING_READMES_DIR, fname)
        if os.path.exists(path_to_readme):
            try:
                with open(path_to_readme, "r", encoding="utf-8") as f_readme:
                    content = f_readme.read()
                used_readme_files_from_source.add(fname)
                # print(f"DEBUG: README ENCONTRADO (Genérico) '{fname}' para módulo '{elixir_module_name_for_lookup}'")
                return content
            except Exception as e:
                print(f"AVISO: Erro ao ler README (Genérico) {path_to_readme}: {e}")
                return f"Erro ao ler README: {path_to_readme}"
    # print(f"DEBUG: README NÃO ENCONTRADO (Genérico) para módulo '{elixir_module_name_for_lookup}', tentados: {potential_filenames}")
    return None

def create_module_scaffold(module_name_key,
                           current_elixir_path_parts, # Caminho do módulo pai DENTRO de DeeperHub
                           readme_content_placeholder="Placeholder",
                           has_facade=True, has_supervisor=True,
                           sub_services=None, sub_schemas=None, sub_workers=None,
                           sub_integrations=None, sub_config=None, sub_plugs=None,
                           sub_controllers=None, sub_views=None, sub_templates=None,
                           sub_channels=None, sub_others=None):

    module_name_pascal = to_pascal_case(module_name_key)
    elixir_module_name_for_this_scaffold = ".".join(["DeeperHub"] + current_elixir_path_parts + [module_name_pascal])

    readme_content = find_existing_readme_content(elixir_module_name_for_this_scaffold)
    if readme_content is None:
        readme_content = readme_content_placeholder
        placeholder_readmes_created.add(elixir_module_name_for_this_scaffold)

    scaffold = {"README.md": readme_content}
    main_module_file_snake = to_snake_case(module_name_pascal)

    if has_facade :
        facade_filename = f"{main_module_file_snake}_facade.ex"
        if module_name_pascal.endswith("Facade"):
            facade_filename = f"{to_snake_case(module_name_pascal)}.ex"
        elif module_name_pascal in ["HTTPClient", "Internationalization", "APIResponder", "InputValidator", "LogSanitizer", "ResponseSanitizer", "DeviceFingerprint", "GeoIP", "Mailer", "ModuleInspector"]:
            facade_filename = f"{main_module_file_snake}.ex"
        scaffold[facade_filename] = f"# Facade for {elixir_module_name_for_this_scaffold}"
    elif module_name_pascal in ["HTTPClient", "Internationalization", "APIResponder", "InputValidator", "LogSanitizer", "ResponseSanitizer", "DeviceFingerprint", "GeoIP", "Mailer", "ModuleInspector"] and not has_facade:
         scaffold[f"{main_module_file_snake}.ex"] = f"# Main module for {elixir_module_name_for_this_scaffold}"

    def process_sub_elements(sub_elements_def, dir_name_key, file_suffix_singular):
        if sub_elements_def:
            dir_name_pascal = to_pascal_case(dir_name_key) # Garante PascalCase para subpastas de módulo
            target_dir_content = {}
            if isinstance(sub_elements_def, dict):
                for name, file_content_or_struct in sub_elements_def.items():
                    parts = name.split('.')
                    current_level_dict = target_dir_content
                    for i, part in enumerate(parts):
                        pascal_part_sub = to_pascal_case(part)
                        if i == len(parts) - 1:
                            target_dir_content[f"{to_snake_case(pascal_part_sub)}.ex"] = file_content_or_struct if isinstance(file_content_or_struct, str) else f"# {file_suffix_singular} {pascal_part_sub}"
                        else: # Subpasta dentro de services, schema, etc.
                            current_level_dict = current_level_dict.setdefault(to_pascal_case(part), {}) # Subpastas também PascalCase
            else:
                for name in sub_elements_def:
                    target_dir_content[f"{to_snake_case(name)}.ex"] = f"# {file_suffix_singular} {to_pascal_case(name)}"
            if target_dir_content:
                 scaffold[dir_name_pascal] = target_dir_content # Usa PascalCase para o nome do diretório
        elif sub_elements_def is None and not isinstance(sub_elements_def, bool) and dir_name_key == "services": # Ajustado para 'services'
             scaffold[to_pascal_case("services")] = {f"default_{to_snake_case(module_name_pascal)}_service.ex": f"# Default Service for {module_name_pascal}"}
        elif sub_elements_def is None and not isinstance(sub_elements_def, bool) and dir_name_key == "schema": # Ajustado para 'schema'
            scaffold[to_pascal_case("schema")] = {f"{to_snake_case(module_name_pascal)}.ex": f"# Main Schema for {module_name_pascal}"}

    process_sub_elements(sub_services, "services", "Service")
    process_sub_elements(sub_schemas, "schema", "Schema")
    process_sub_elements(sub_workers, "workers", "Worker")
    process_sub_elements(sub_integrations, "integrations", "Integration")
    process_sub_elements(sub_config, "config", "Config")
    process_sub_elements(sub_plugs, "plugs", "Plug")
    process_sub_elements(sub_controllers, "controllers", "Controller")
    process_sub_elements(sub_views, "views", "View")
    process_sub_elements(sub_templates, "templates", "Template")
    process_sub_elements(sub_channels, "channels", "Channel")

    if sub_others:
        for other_file, other_content in sub_others.items():
            scaffold[other_file] = other_content
    if has_supervisor:
        scaffold["supervisor.ex"] = f"# Supervisor for {elixir_module_name_for_this_scaffold}"
    return scaffold

# --- ESTRUTURA (COPIADA DA V3, AJUSTES FEITOS NO create_module_scaffold e chamadas) ---
CATEGORIZED_STRUCTURE = {
    "Application": create_module_scaffold("Application", [], readme_content_placeholder="Main Application Logic", has_facade=False, sub_services=False, sub_schemas=False, sub_others={"application.ex": "# DeeperHub.Application (Application Behaviour)"}),
    "Core": {
        "__init__.ex": "# DeeperHub.Core (Context - for README)",
        "ConfigManager": create_module_scaffold("ConfigManager", ["Core"], sub_schemas=["Setting"], sub_services={"Setting": "# Setting Service (GenServer)"}),
        "EventBus": create_module_scaffold("EventBus", ["Core"], sub_services={"EventBus": "# EventBus GenServer"}, has_facade=False),
        "Logger": create_module_scaffold("Logger", ["Core"], sub_services={"StructuredLogger": "# GenServer", "DistributedTracing": ""}, sub_config=["LoggerConfig"]),
        "Metrics": create_module_scaffold("Metrics", ["Core"], sub_services={"EtsMetricsService": "", "MetricsCollector": "", "MetricsExporter": "", "MetricsAnalyzer": "", "MetricsAlerts": "", "SystemMonitor":""}, sub_integrations={"BackgroundTasksMetricsIntegration": "", "FeatureFlagsMetricsIntegration": "", "FraudMetricsIntegration": "", "RecoveryMetricsIntegration": "", "WebhooksMetricsIntegration":""}),
        "Repo": {"README.md": find_existing_readme_content("DeeperHub.Core.Repo") or "Placeholder for Core.Repo", "repo.ex": "# Ecto Repo"},
        "BackgroundTaskManager": create_module_scaffold("BackgroundTaskManager", ["Core"], sub_services=["DefaultBackgroundTaskService"], sub_workers=["CleanupWorker"]),
        "CircuitBreakerFactory": create_module_scaffold("CircuitBreakerFactory", ["Core"], sub_services={"CircuitBreaker": "# GenServer", "CircuitBreakerRegistry": ""}),
        "Cache": create_module_scaffold("Cache", ["Core"], sub_services={"EtsCache": "", "CacheManager":""}, sub_workers=["MetricsReporter", "CacheStats"]),
        "EncryptionService": create_module_scaffold("EncryptionService", ["Core"], sub_services={"KeyManagementService": "", "AtRestEncryptionService":""}, sub_schemas={"EncryptedType":""}),
        "HTTPClient": create_module_scaffold("HTTPClient", ["Core"], sub_services={"AdapterBehaviour": "", "Adapters.FinchAdapter":""}, sub_schemas={"Response":"", "Error":""}, has_facade=False, sub_others={"http_client.ex": "# Facade is the main module"}),
        "Internationalization": create_module_scaffold("Internationalization", ["Core"], sub_services={"BackendBehaviour":"", "Backends.GettextAdapter":"", "Locale":"", "Formatters":""}, has_facade=False, sub_others={"i18n.ex": "# Facade is the main module"}),
        "APIResponder": create_module_scaffold("APIResponder", ["Core"], has_facade=False, sub_services=False, sub_schemas=False, has_supervisor=False, sub_others={"api_responder.ex":"# Module with response functions"}),
        "InputValidator": create_module_scaffold("InputValidator", ["Core"], sub_services={"Validators.EmailValidator":"", "Sanitizers.HTMLSanitizer":""}, has_facade=False, sub_schemas=False, has_supervisor=False, sub_others={"input_validator.ex":"# Facade is the main module", "error_formatter.ex":"# Error formatting"}),
        "GeoIP": create_module_scaffold("GeoIP", ["Core"], sub_services={"Adapters.MaxMindDBAdapter":""}, sub_schemas={"LocationData":""})
    },
    "Accounts": create_module_scaffold(
        "Accounts", [],
        sub_services=["UserService", "ProfileService", "RegistrationService"],
        sub_schemas=["User", "Profile"],
        sub_workers=["EmailVerificationWorker", "SessionCleanupWorker"],
        sub_integrations=["EventIntegration"],
        sub_config=["FeatureFlags"]
    ),
    "Authentication": {
        "__init__.ex": "# DeeperHub.Authentication (Context)",
        "Auth": create_module_scaffold("Auth", ["Authentication"], sub_services=["AuthService", "LoginService", "SessionService", "TokenService", "PermissionService", "RoleService"], sub_schemas={"AuthToken":"", "Permission":"", "Role":"", "RolePermission":"", "UserPermission":"", "UserRole":""}, sub_integrations=["AuditIntegration", "EventIntegration"], sub_config=["RateLimitIntegration"]),
        "MFA": create_module_scaffold("MFA", ["Authentication"], sub_services=["MFAService", "MFAPolicyService", "PushVerificationService", "RecoveryCodeService", "TOTPService", "WebAuthnService"], sub_schemas={"RecoveryCode":"", "PushDevice":"", "TOTP":""}, sub_integrations=["MFAAnomalyIntegration", "MFANotificationIntegration"]),
        "OAuth": create_module_scaffold("OAuth", ["Authentication"], sub_services=["DefaultOAuthService", "CallbackService", "ProviderService", "OAuthCircuitBreaker"], sub_schemas=["OAuthToken"], sub_integrations=["EventIntegration", "OAuthApiIntegration"], sub_config={"UserInfoCache":""}),
        "WebAuthn": create_module_scaffold("WebAuthn", ["Authentication"], sub_services=["WebAuthnService"], sub_schemas=["Credential"]),
        "Tokens": create_module_scaffold("Tokens", ["Authentication"], sub_services=["DefaultTokenService", "JwtService", "TokenRotationService", "BlacklistService"], sub_schemas=["ApiToken", "TokenBlacklist"], sub_workers=["BlacklistCleanupWorker", "TokenRotationWorker"]),
        "RBAC": create_module_scaffold("RBAC", ["Authentication"], sub_services=["AccessControlService", "PermissionService", "RoleService", "RoleHierarchyService", "TemporaryPermissionService", "RBACAuditService", "RBACInitializer"], sub_schemas={"Permission":"", "Role":"", "RoleHierarchy":"", "RolePermission":"", "UserRole":"","TemporaryPermission":""}, sub_integrations=["AuditIntegration", "EventIntegration"], sub_config={"PermissionsCache":""}),
        "SecurityQuestions": create_module_scaffold("SecurityQuestions", ["Authentication"], sub_services=["DefaultSecurityQuestionService"], sub_schemas=["Question", "Answer"]),
        "SessionPolicy": create_module_scaffold("SessionPolicy", ["Authentication"], sub_services=["DefaultSessionPolicyService"], sub_schemas=["Policy", "PolicyException"]),
        "TemporaryPassword": create_module_scaffold("TemporaryPassword", ["Authentication"], sub_services=["TemporaryPasswordService"], sub_schemas=["TempPassword"], sub_workers=["CleanupWorker"]),
        "Recovery": create_module_scaffold("Recovery", ["Authentication"], sub_services=["DefaultRecoveryService", "PasswordResetService", "EmailVerificationService"], sub_schemas={"PasswordReset":"", "EmailVerification":""}, sub_integrations=["AuditIntegration", "EventIntegration"], sub_config=["RateLimitIntegration"])
    },
    "Security": {
        "__init__.ex": "# DeeperHub.Security (Context)",
        "security_facade.ex": "# Facade Geral de Segurança (ou SecurityManager)",
        "supervisor.ex": "# Supervisor Geral de Segurança",
        "Config": {"ip_firewall_config.ex": "", "feature_flags.ex":""},
        "Validation": {"security_input_validation.ex": ""},
        "Cache": {"security_cache.ex":"", "security_cache_supervisor.ex":""},
        "Integrations": {"cache_integration.ex":"","event_integration.ex":"","rbac_integration.ex":"","risk_auth_integration.ex":"","risk_fraud_integration.ex":"","risk_notification_integration.ex":""},
        "Plugs": {"ip_firewall_plug.ex":""},
        "AdminAuth": create_module_scaffold("AdminAuth", ["Security"], sub_services=["AdminAuthService", "AdminTOTPService", "AdminTokenService", "PermissionService", "AdminActionAuthService"], sub_schemas=["AdminSchema", "AdminTOTP", "AdminToken", "AdminAction", "AdminActionLog", "AdminActionRisk", "AdminActionVerification"]),
        "AtRestEncryption": create_module_scaffold("AtRestEncryption", ["Security"], has_facade=False, sub_services=False, sub_schemas=False, has_supervisor=False, sub_others={"at_rest_encryption_service.ex":"# Uses Core.EncryptionService"}),
        "BehavioralAnalysis": create_module_scaffold("BehavioralAnalysis", ["Security"], sub_services=["DefaultBehavioralAnalysisService", "AnomalyDetectionService", "PatternAnalysisService", "BehavioralAnalysisCore", "BehavioralAnalysisPatterns", "BehavioralAnalysisProfiles", "BehavioralAnalysisReporting", "UserBehaviorAnalysisService"], sub_schemas=["BehaviorProfileSchema"]),
        "BruteForceProtection": create_module_scaffold("BruteForceProtection", ["Security"], sub_services=["DefaultBruteForceProtectionService"], sub_workers=["CleanupWorker"]),
        "CsrfProtection": create_module_scaffold("CsrfProtection", ["Security"], sub_services=["CsrfProtectionService"]),
        "DataMasking": create_module_scaffold("DataMasking", ["Security"], sub_services=["DataMaskingService"]),
        "DdosProtection": create_module_scaffold("DdosProtection", ["Security"], sub_services=["DdosProtectionService"]),
        "DeviceManagement": create_module_scaffold("DeviceManagement", ["Security"], sub_services={"DeviceService":""}, sub_schemas={"Device":""}, has_facade=True, sub_others={"device_fingerprint.ex":"# Logic"}),
        "FraudDetection": create_module_scaffold("FraudDetection", ["Security"], sub_services=["DefaultFraudDetectionService", "DetectionRecorder", "FraudNotifier", "RiskCalculator", "RulesManager"], sub_schemas={"FraudDetectionSchema":"", "RiskFactors":"", "RiskScore":""}, sub_integrations=["AuditIntegration"], sub_workers=["AnalysisWorker", "CleanupWorker"]),
        "GeoLocation": create_module_scaffold("GeoLocation", ["Security"], sub_services=["GeoLocationService"], sub_schemas={"LocationHistory":"", "TrustedLocation":""}, has_facade=True),
        "Hashing": create_module_scaffold("Hashing", ["Security"], sub_services=["HashingService"], has_supervisor=False),
        "IntrusionDetection": create_module_scaffold("IntrusionDetection", ["Security"], sub_services=["IntrusionDetectionService", "IPBlockingService", "AttackDetectionService", "CaptchaService", "ContextAuthenticationService"]),
        "IPFirewall": create_module_scaffold("IPFirewall", ["Security"], sub_services=["IpFirewallService"], sub_config=["IpFirewallConfig"], sub_schemas={"IpAllow":"", "IpBlock":""}, has_facade=False),
        "LogSanitizer": create_module_scaffold("LogSanitizer", ["Security"], has_facade=False, sub_services=False, sub_schemas=False, has_supervisor=False, sub_others={"log_sanitizer.ex":"# Logic"}),
        "SecurityMonitoring": create_module_scaffold("SecurityMonitoring", ["Security"], sub_services=["SecurityMonitoringService", "SecurityMonitoringAlerts", "SecurityMonitoringEvents", "SecurityMonitoringNotifications", "SecurityMonitoringStatistics"]),
        "PathTraversalProtection": create_module_scaffold("PathTraversalProtection", ["Security"], sub_services=["PathTraversalProtectionService"]),
        "PolicyManager": create_module_scaffold("PolicyManager", ["Security"], sub_services={"SecurityPolicyAuthorization":""}, has_facade=False, has_supervisor=False, sub_others={"security_policy_manager.ex":"# Facade/Service"}),
        "ResponseSanitizer": create_module_scaffold("ResponseSanitizer", ["Security"], has_facade=False, sub_services=False, sub_schemas=False, has_supervisor=False, sub_others={"response_sanitizer.ex":"# Logic"}),
        "RiskAssessment": create_module_scaffold("RiskAssessment", ["Security"], sub_services=["DefaultRiskAssessmentService", "AdvancedRiskFactors", "RiskActionRecommender", "RiskCalculator", "RiskFactorCalculator", "RiskWeightCalibrator"], sub_config={"RiskMetricsCollector":""}),
        "SqlInjectionProtection": create_module_scaffold("SqlInjectionProtection", ["Security"], sub_services=["SqlInjectionProtectionService"]),
        "XssProtection": create_module_scaffold("XssProtection", ["Security"], sub_services=["XssProtectionService"]),
    },
    "Communication": {
        "__init__.ex": "# DeeperHub.Communication (Context)",
        "Notifications": create_module_scaffold("Notifications", ["Communication"], sub_services=["DefaultNotificationService", "HistoryService", "PreferencesService", "SecurityNotificationService", "TokenNotifications"], sub_schemas={"Notification":"", "NotificationPreference":"", "ScheduledNotification":""}, sub_config={"Cache.PreferencesCache":"", "Cache.TemplateCache":"", "Templates.I18n.PtBr":"", "Templates.I18n.Translator":"", "Templates.TemplateManager":""}, sub_channels={"EmailChannel":"", "InAppChannel":"", "PushChannel":""}, sub_integrations=["AuditIntegration", "EventIntegration", "BackgroundTasksNotificationIntegration", "FeatureFlagsNotificationIntegration", "FraudNotificationIntegration", "RecoveryNotificationIntegration", "WebhooksNotificationIntegration"], sub_workers=["EmailWorker", "InAppWorker", "MetricsWorker", "NotificationWorker", "PushWorker", "RetentionWorker", "ScheduledNotificationWorker"]),
        "Mailer": create_module_scaffold("Mailer", ["Communication"], sub_services={"DefaultMailerService":""}, sub_integrations=["SmtpServiceIntegration"], sub_others={"email.ex":"# Email Struct", "adapter_behaviour.ex":""}),
        "Webhooks": create_module_scaffold("Webhooks", ["Communication"], sub_services={"WebhookService":"" , "WebhookDispatcher":"", "AutoHealing":"", "DispatcherWithCircuitBreaker":"", "EventLogic":"# Renomeado de Event para EventLogic", "Monitor":"","PayloadSigner":"", "Scheduler":""}, sub_schemas={"Webhook":"", "WebhookEvent":""}, sub_integrations=["AuditIntegration"], sub_workers=["CleanupWorker", "DeliveryWorker", "HealthCheckWorker"])
    },
    "Domain": {
        "__init__.ex": "# DeeperHub.Domain (Context)",
        "Servers": create_module_scaffold("Servers", ["Domain"], sub_services=["DefaultServersService"], sub_schemas={"Server":"", "Invite":"", "Rating":""}, sub_config=["RateLimitIntegration"]),
        "ServerAdvertisements": create_module_scaffold("ServerAdvertisements", ["Domain"], sub_services=["AdvertisementService"], sub_schemas=["Advertisement"]),
        "ServerAlerts": create_module_scaffold("ServerAlerts", ["Domain"], sub_services=["AlertService"], sub_schemas=["Alert"]),
        "ServerEvents": create_module_scaffold("ServerEvents", ["Domain"], sub_services=["EventService"], sub_schemas={"EventSchema":"# Renomeado para evitar conflito com Core.EventBus.Event"}),
        "ServerPackages": create_module_scaffold("ServerPackages", ["Domain"], sub_services=["PackageService"], sub_schemas=["ServerPackage"]),
        "ServerReviews": create_module_scaffold("ServerReviews", ["Domain"], sub_services=["ReviewService"], sub_schemas=["Review"], sub_config=["RateLimitIntegration", "SecurityIntegration"]),
        "ServerTags": create_module_scaffold("ServerTags", ["Domain"], sub_services=["TagService"], sub_schemas={"Tag":"", "ServerTagLink":""}),
        "ServerUpdateMessages": create_module_scaffold("ServerUpdateMessages", ["Domain"], sub_services={"UpdateMessageService":"# Service"}, sub_schemas={"UpdateMessage":"# Schema"}),
        "Gamification": {
            "__init__.ex": "# DeeperHub.Domain.Gamification (Context)",
            "Achievements": create_module_scaffold("Achievements", ["Domain", "Gamification"], sub_services=["DefaultAchievementsService"], sub_schemas=["Achievement", "UserAchievement"]),
            "Challenges": create_module_scaffold("Challenges", ["Domain", "Gamification"], sub_services=["DefaultChallengesService"], sub_schemas=["Challenge", "UserChallenge"]),
            "Rewards": create_module_scaffold("Rewards", ["Domain", "Gamification"], sub_services=["DefaultRewardsService"], sub_schemas=["Reward", "UserReward"])
        },
        "Support": create_module_scaffold("Support", ["Domain"], sub_services=["DefaultSupportService"], sub_schemas={"SupportTicket":"", "TicketMessage":""}, sub_integrations=["NotificationIntegration"], sub_config=["RateLimitIntegration"]),
        "UserInteractions": create_module_scaffold("UserInteractions", ["Domain"], sub_services={"DefaultUserInteractionsService":"", "FavoriteService":"", "MessagingService":""}, sub_schemas={"Favorite":"","ChatMessage":"","Report":"","Feedback":"","Recommendation":""}),
        "Lists": create_module_scaffold("Lists", ["Domain"], sub_services={"ListManagementService":"# Or Storage.ex"}, sub_schemas={"Category":"","Platform":"","Language":"","AchievementType":"","ContentType":"","Engine":"","FeedbackType":"","Network":"","Reputation":"","StatusType":"# Renomeado", "TagSystem":"# Renomeado"}),
        "Search": create_module_scaffold("Search", ["Domain"], sub_services={"AdvancedSearch":"", "RelevanceSearch":"", "SearchSuggestionsLogic":"# Renomeado", "RealtimeSuggestions":""}, sub_schemas={"SearchHistory":""}, has_facade=True)
    },
    "APIGateway": {
        "__init__.ex": "# DeeperHub.APIGateway (Context)",
        "router.ex": "# API Router (Phoenix, chama controllers)",
        "Controllers": {
            "accounts_controller.ex": "", "servers_controller.ex": "", "auth_controller.ex": ""
        },
        "Views": {
            "accounts_view.ex": "", "servers_view.ex": "", "error_view.ex": ""
        },
        "Plugs": {
            "authentication_plug.ex": "", "authorization_plug.ex": "", "rate_limit_plug.ex": ""
        },
        "Validation": {
             "request_schemas.ex": "# Schemas para validar payloads de API"
        },
        "supervisor.ex": "# Supervisor (se houver GenServers específicos da API)"
    },
    "Console": create_module_scaffold(
        "Console", [],
        sub_services=["CommandRegistry", "CommandRunner", "OutputService"],
        sub_config=["ConsoleConfig"],
        sub_others={
            "Commands": {
                "help_command.ex": "# HelpCommand module", "user_commands.ex": "# User related commands"
            },
            "command_behaviour.ex": "# Behaviour for commands"
        },
        sub_integrations=["AuditIntegration", "NotificationIntegration"]
    ),
    "DevTools": {
        "__init__.ex": "# DeeperHub.DevTools (Context)",
        "ModuleInspector": create_module_scaffold("ModuleInspector", ["DevTools"], sub_services={"ModuleInspector":"# Logic", "FunctionInspector":"", "TypeSpecInspector":""}, sub_schemas={"ModuleInfo":"# Schema", "FunctionInfo":"", "TypeSpecInfo":""}, has_facade=True, sub_others={"inspector_repo.ex":"# Ecto Repo"})
    },
    "Shared": {
        "__init__.ex": "# DeeperHub.Shared (Context)",
        "Utils": create_module_scaffold("Utils", ["Shared"], sub_services=False, sub_schemas=False, has_facade=False, has_supervisor=False,
            sub_others={
                "date_utils.ex": "# DateUtils", "file_utils.ex": "# FileUtils", "list_utils.ex": "# ListUtils",
                "map_utils.ex": "# MapUtils", "security_utils.ex": "# Basic SecurityUtils",
                "string_utils.ex": "# StringUtils", "validation_utils.ex": "# Basic ValidationUtils"
            }),
        "Formatters": { "json_formatter.ex": "# JsonFormatter" }
    }
}

PHOENIX_APP_ROOT_STRUCTURE = {
    "lib": {
        "deeper_hub": CATEGORIZED_STRUCTURE,
        "deeper_hub_web": {
            "__init__.ex": "# DeeperHubWeb (Context - for README)",
            "endpoint.ex": "# Phoenix Endpoint",
            "router.ex": "# Phoenix Router",
            "Controllers": { "page_controller.ex": "# PageController" },
            "Views": { "layout_view.ex": "", "page_view.ex": "" },
            "templates": { # Convenção Phoenix usa minúsculo para estas pastas
                "layout": {"app.html.heex": "<.flash_group flash={@flash} />\n<%= @inner_content %>"},
                "page": {"index.html.heex": "<h1>Welcome to DeeperHub!</h1>"}
            },
            "assets.ex": "# Asset pipeline",
        }
    },
    "priv": {
        "repo": {
            "migrations": { ".formatter.exs": "import Config\n\n[inputs: [\"*.{ex,exs}\", \"priv/*/seeds.exs\"] ++ Mix.Project.config()[:inputs]]\n" },
            "seeds.exs": "# Database seed data"
        },
        "gettext": {
            "en": {"LC_MESSAGES": {"default.po": "# English translations"}},
            "pt_BR": {"LC_MESSAGES": {"default.po": "# Portuguese translations"}}
        },
        "static": { "favicon.ico": "# Placeholder", "robots.txt": "User-agent: *\nDisallow:\n" }
    },
    "test": {
        "deeper_hub": { "Core": {"config_manager_test.exs": "# Test for ConfigManager"} },
        "deeper_hub_web": { "Controllers": {"page_controller_test.exs": "# Test for PageController"} },
        "support": { "conn_case.ex": "", "data_case.ex": "", "channel_case.ex": "" },
        "test_helper.exs": "ExUnit.start()"
    },
    "config": {
        "config.exs": "", "dev.exs": "", "test.exs": "", "prod.exs": "", "runtime.exs": ""
    },
    "assets": { "css": {"app.css": ""}, "js": {"app.js": ""}, "vendor": {} },
    "mix.exs": "# Mix project file - CONTENT BELOW",
    "README.md": "# README Principal do Projeto DeeperHub",
    ".formatter.exs": "import Config\n\n[inputs: [\"*.{ex,exs}\", \"priv/*/seeds.exs\"] ++ Mix.Project.config()[:inputs]]\n",
    ".gitignore": "/deps\n/_build\n/*.beam\n/priv/static/assets*\n/assets/node_modules\n"
}

# --- FUNÇÃO PRINCIPAL DE CRIAÇÃO DA ESTRUTURA (AJUSTADA) ---
def create_project_structure(base_path, structure_def, current_os_path_parts=None, current_elixir_module_prefix_parts=None):
    if current_os_path_parts is None: current_os_path_parts = []
    if current_elixir_module_prefix_parts is None: current_elixir_module_prefix_parts = []

    for name_key, content_or_structure in structure_def.items():
        os_item_name = name_key
        # Decide se o nome do diretório deve ser PascalCase
        is_elixir_module_context_dir = isinstance(content_or_structure, dict) and \
                               name_key.lower() not in [
                                   "lib", "test", "priv", "config", "assets", "css", "js", "vendor",
                                   "lc_messages", "migrations", "repo", "gettext", "support", #Phoenix support dir
                                   "layout", "page", "templates", "channels", #Phoenix dirs
                                   "controllers", "views", "plugs", "validation", "integrations", #Sub-dirs comuns
                                   "workers", "schema", "services", "backends", "adapters", "config",
                                   "policies", "examples", "cache", "metrics", "i18n", "commands",
                                   "utils", "formatters"
                               ] and not name_key.startswith(".")

        if is_elixir_module_context_dir:
            os_item_name = to_pascal_case(name_key)

        current_item_full_os_path = os.path.join(base_path, *current_os_path_parts, os_item_name)

        # Constrói o prefixo do módulo Elixir para os itens DENTRO deste diretório
        next_elixir_module_prefix_parts = list(current_elixir_module_prefix_parts)
        if is_elixir_module_context_dir:
            pascal_key = to_pascal_case(name_key)
            # Adiciona ao prefixo somente se não for redundante
            if not next_elixir_module_prefix_parts or next_elixir_module_prefix_parts[-1] != pascal_key:
                next_elixir_module_prefix_parts.append(pascal_key)

        # Caso especial para lib/deeper_hub e lib/deeper_hub_web
        is_entering_deeper_hub_lib = (current_os_path_parts == ["lib"] and name_key == "deeper_hub")
        is_entering_deeper_hub_web_lib = (current_os_path_parts == ["lib"] and name_key == "deeper_hub_web")


        if isinstance(content_or_structure, dict): # É um diretório
            os.makedirs(current_item_full_os_path, exist_ok=True)

            # Processa o README do diretório (definido em __init__.ex)
            if "__init__.ex" in content_or_structure:
                readme_placeholder_content = content_or_structure["__init__.ex"]

                # Nome do módulo Elixir para este diretório/contexto
                # Se for um contexto de primeiro nível como "Core", "Accounts", etc.
                elixir_context_name = "DeeperHub"
                if next_elixir_module_prefix_parts: # Se já tem partes como ['Core'], ['Authentication']
                    elixir_context_name += "." + ".".join(next_elixir_module_prefix_parts)
                elif is_entering_deeper_hub_web_lib: # Para lib/deeper_hub_web
                    elixir_context_name = "DeeperHubWeb"

                readme_content = find_existing_readme_content(elixir_context_name)
                readme_file_path = os.path.join(current_item_full_os_path, "README.md")

                with open(readme_file_path, "w", encoding="utf-8") as f_readme_file:
                    if readme_content:
                        f_readme_file.write(readme_content)
                    else:
                        placeholder_readmes_created.add(elixir_context_name)
                        f_readme_file.write(f"# README for {elixir_context_name}\n\n{readme_placeholder_content}\n\n*Este é um placeholder.*")
                # print(f"Criado: {readme_file_path} (README de diretório para {elixir_context_name})")

            create_project_structure(base_path,
                                     {k:v for k,v in content_or_structure.items() if k != "__init__.ex"},
                                     current_os_path_parts + [os_item_name],
                                     next_elixir_module_prefix_parts)
        else: # É um arquivo
            os.makedirs(os.path.dirname(current_item_full_os_path), exist_ok=True)
            with open(current_item_full_os_path, "w", encoding="utf-8") as f:
                if name_key.endswith(".md"):
                    f.write(content_or_structure)
                elif name_key.endswith((".ex", ".exs")):
                    file_base_snake = to_snake_case(name_key.split('.')[0])
                    file_module_pascal = to_pascal_case(file_base_snake)

                    # Determina o prefixo do módulo Elixir para este arquivo
                    elixir_module_name = "DeeperHub" # Padrão
                    if current_elixir_module_prefix_parts:
                        elixir_module_name += "." + ".".join(current_elixir_module_prefix_parts)

                    # Adiciona o nome do arquivo ao módulo, evitando duplicação
                    # Ex: DeeperHub.Core + ConfigManager -> DeeperHub.Core.ConfigManager
                    # Mas DeeperHub.Core.ConfigManager + config_manager_facade.ex -> DeeperHub.Core.ConfigManager.Facade
                    if not elixir_module_name.endswith(file_module_pascal):
                        # Lógica para sufixos como _facade, _service
                        is_special_suffix = False
                        for suffix in ["Facade", "Service", "Schema", "Worker", "Integration", "Config", "Controller", "View", "Plug", "Channel", "Behaviour", "Adapter", "Supervisor"]:
                            if file_module_pascal.endswith(suffix) and file_module_pascal != suffix:
                                base_file_module = file_module_pascal[:-len(suffix)]
                                if elixir_module_name.endswith(base_file_module): # Ex: Modulo + ModuloFacade
                                    elixir_module_name += "." + suffix
                                    is_special_suffix = True
                                    break
                        if not is_special_suffix:
                            elixir_module_name += "." + file_module_pascal

                    # Casos especiais para arquivos na raiz do projeto ou web
                    if current_item_full_os_path == os.path.join(base_path, "lib", "deeper_hub.ex"):
                        elixir_module_name = "DeeperHub.Application"
                    elif current_item_full_os_path.startswith(os.path.join(base_path, "lib", "deeper_hub_web")):
                        web_parts = current_os_path_parts[current_os_path_parts.index("deeper_hub_web") + 1:] + [file_module_pascal]
                        # Remove duplicatas se o nome do arquivo for igual ao último diretório
                        clean_web_parts = []
                        last_wp = None
                        for wp in web_parts:
                            if wp != last_wp:
                                clean_web_parts.append(wp)
                            last_wp = wp
                        elixir_module_name = "DeeperHubWeb." + ".".join(clean_web_parts)
                        if elixir_module_name == "DeeperHubWeb.Endpoint.Endpoint": elixir_module_name = "DeeperHubWeb.Endpoint"
                        if elixir_module_name == "DeeperHubWeb.Router.Router": elixir_module_name = "DeeperHubWeb.Router"
                        if elixir_module_name == "DeeperHubWeb.Assets.Assets": elixir_module_name = "DeeperHubWeb.Assets"


                    if name_key == "mix.exs":
                        f.write(f"""
defmodule DeeperHub.MixProject do
  use Mix.Project

  def project do
    [
      app: :deeper_hub,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers() ++ [:gettext],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      name: "DeeperHub",
      source_url: "https://github.com/your_username/deeper_hub",
      homepage_url: "https://your_project_homepage.com",
      docs: [
        main: "DeeperHub",
        # logo: "priv/static/assets/logo.png",
        extras: ["README.md"]
                ++ Path.wildcard("lib/deeper_hub/*/README.md")
                ++ Path.wildcard("lib/deeper_hub/*/*/README.md")
                ++ Path.wildcard("lib/deeper_hub/*/*/*/README.md")
      ]
    ]
  end

  def application do
    [
      mod: {{DeeperHub.Application, []}},
      extra_applications: [:logger, :runtime_tools, :crypto, :inets, :ssl]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {{:jason, "~> 1.4"}},
      {{:gettext, "~> 0.23"}},
      {{:telemetry_metrics, "~> 1.0"}},
      {{:telemetry_poller, "~> 1.0"}},
      {{:ex_doc, "~> 0.31", only: :dev, runtime: false}}
    ]
  end

  defp aliases do [ ] end
end
""")
                    else:
                        module_doc_content = content_or_structure.replace("\"", "\\\"")
                        f.write(f"defmodule {elixir_module_name} do\n")
                        if content_or_structure and not content_or_structure.startswith("#"):
                            f.write(f"  @moduledoc \"\"\"\n  {module_doc_content}\n  \"\"\"\n\n")
                        elif content_or_structure and content_or_structure.startswith("#"):
                             f.write(f"  @moduledoc false\n  {content_or_structure}\n\n")
                        else:
                            f.write("  @moduledoc false\n\n")
                        f.write(f"  # TODO: Implement {elixir_module_name} logic\n")
                        f.write(f"end\n")
                else:
                    f.write(content_or_structure)
            print(f"Criado: {current_item_full_os_path}")

def main():
    global all_readme_files_in_source_dir
    if os.path.exists(EXISTING_READMES_DIR):
        for filename in os.listdir(EXISTING_READMES_DIR):
            if filename.endswith('.md'):
                all_readme_files_in_source_dir.add(filename)
    else:
        print(f"AVISO: Diretório de READMEs existentes '{EXISTING_READMES_DIR}' não foi encontrado.")

    if os.path.exists(PROJECT_ROOT):
        print(f"O diretório '{PROJECT_ROOT}' já existe. Removendo e recriando...")
        shutil.rmtree(PROJECT_ROOT)
    os.makedirs(PROJECT_ROOT)
    print(f"Diretório base '{PROJECT_ROOT}' criado.")

    # A primeira chamada para lib/deeper_hub deve ter current_elixir_module_prefix_parts como []
    # A flag is_lib_deeper_hub_context não é mais necessária, a lógica de prefixo é tratada em get_elixir_module_name
    create_project_structure(PROJECT_ROOT, PHOENIX_APP_ROOT_STRUCTURE, current_elixir_module_prefix_parts=[])


    print("\nEstrutura do projeto DeeperHub (categorizada V4.1) criada com sucesso!")
    print(f"Verifique a pasta: {os.path.abspath(PROJECT_ROOT)}")

    print("\n--- RELATÓRIO DE READMEs ---")
    unused_readmes = all_readme_files_in_source_dir - used_readme_files_from_source
    if unused_readmes:
        print(f"\n{len(unused_readmes)} READMEs EXISTENTES NÃO UTILIZADOS:")
        for readme in sorted(list(unused_readmes)):
            print(f"  - {readme}")
    else:
        print("\nTodos os READMEs existentes na pasta de origem foram utilizados ou explicitamente mapeados.")

    if placeholder_readmes_created:
        print(f"\n{len(placeholder_readmes_created)} READMEs FALTANTES (PLACEHOLDERS CRIADOS PARA OS MÓDULOS/CONTEXTOS):")
        for readme_path_module_name in sorted(list(placeholder_readmes_created)):
            print(f"  - {readme_path_module_name}")
    else:
        print("\nNenhum placeholder de README foi criado; todos os módulos/contextos definidos na estrutura encontraram um README ou o placeholder original foi usado.")

if __name__ == "__main__":
    main()
