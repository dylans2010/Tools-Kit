import os
directory = 'Sources/Views/Workspace/Developer'
files = [f for f in os.listdir(directory) if f.endswith('.swift')]
new_systems = [
    "SDKProjectArchitectView.swift", "PluginInstallerView.swift", "ConnectorAuthRegistryView.swift",
    "AppLifecycleView.swift", "DeveloperOnboardingView.swift", "DistributionPipelineView.swift",
    "BuildArtifactStoreView.swift", "EnvironmentVaultView.swift", "ResourceQuotaView.swift",
    "AppConfigSyncView.swift", "AutomatedTestRunnerView.swift", "BetaTesterRecruitmentView.swift",
    "ErrorRegressionView.swift", "DependencyScannerView.swift", "LocalizationAuditView.swift",
    "StructuredLogViewerView.swift", "APITrafficInspectorView.swift", "DatabaseMigrationView.swift",
    "PerformanceProfilingView.swift", "CanaryRolloutView.swift"
]
for ns in new_systems:
    if ns in files:
        print(f"[FOUND] {ns}")
    else:
        print(f"[MISSING] {ns}")
