import Foundation

public struct SDKDependencyResolution: Identifiable, Sendable {
    public let id = UUID()
    public let orderedModules: [SDKModuleDescriptor]
    public let conflicts: [DependencyConflict]
    public let warnings: [String]
    public let resolvedAt: Date

    public var isClean: Bool { conflicts.isEmpty }
}

public struct DependencyConflict: Identifiable, Sendable {
    public let id = UUID()
    public let moduleA: String
    public let moduleB: String
    public let conflictType: ConflictType
    public let description: String

    public enum ConflictType: String, Sendable {
        case versionMismatch, circularDependency, capabilityCollision, missingDependency
    }
}

public final class SDKDependencyGraph {
    public init() {}

    public func resolve(modules: [SDKModuleDescriptor]) -> SDKDependencyResolution {
        var ordered: [SDKModuleDescriptor] = []
        var visited = Set<String>()
        var visiting = Set<String>()
        var conflicts: [DependencyConflict] = []
        var warnings: [String] = []
        let moduleMap = Dictionary(uniqueKeysWithValues: modules.map { ($0.identifier, $0) })

        func visit(_ identifier: String) {
            if visited.contains(identifier) { return }
            if visiting.contains(identifier) {
                conflicts.append(DependencyConflict(
                    moduleA: identifier,
                    moduleB: identifier,
                    conflictType: .circularDependency,
                    description: "Circular dependency detected involving '\(identifier)'"
                ))
                return
            }

            visiting.insert(identifier)

            if let mod = moduleMap[identifier] {
                for dep in mod.dependencies {
                    if moduleMap[dep] == nil {
                        conflicts.append(DependencyConflict(
                            moduleA: identifier,
                            moduleB: dep,
                            conflictType: .missingDependency,
                            description: "'\(identifier)' requires '\(dep)' which is not registered"
                        ))
                    } else {
                        visit(dep)
                    }
                }
                ordered.append(mod)
            }

            visiting.remove(identifier)
            visited.insert(identifier)
        }

        for mod in modules.sorted(by: { $0.loadPriority < $1.loadPriority }) {
            visit(mod.identifier)
        }

        conflicts.append(contentsOf: detectVersionConflicts(modules: modules))
        conflicts.append(contentsOf: detectCapabilityCollisions(modules: modules))

        if modules.count > 50 {
            warnings.append("Large module graph (\(modules.count) modules) may impact startup time")
        }

        return SDKDependencyResolution(
            orderedModules: ordered,
            conflicts: conflicts,
            warnings: warnings,
            resolvedAt: Date()
        )
    }

    public func validateAddition(of newModule: SDKModuleDescriptor, to existing: [SDKModuleDescriptor]) -> [String] {
        var issues: [String] = []
        let existingIds = Set(existing.map(\.identifier))

        for dep in newModule.dependencies where !existingIds.contains(dep) {
            issues.append("Missing dependency: '\(dep)'")
        }

        if existing.contains(where: { $0.identifier == newModule.identifier }) {
            issues.append("Module '\(newModule.identifier)' already registered")
        }

        let resolution = resolve(modules: existing + [newModule])
        for conflict in resolution.conflicts where conflict.moduleA == newModule.identifier || conflict.moduleB == newModule.identifier {
            issues.append(conflict.description)
        }

        return issues
    }

    private func detectVersionConflicts(modules: [SDKModuleDescriptor]) -> [DependencyConflict] {
        var conflicts: [DependencyConflict] = []
        var seen: [String: (String, String)] = [:]

        for mod in modules {
            for dep in mod.dependencies {
                if let existing = seen[dep], existing.1 != mod.identifier {
                    let depModA = modules.first { $0.identifier == dep }
                    let _ = depModA
                } else {
                    seen[dep] = (dep, mod.identifier)
                }
            }
        }

        return conflicts
    }

    private func detectCapabilityCollisions(modules: [SDKModuleDescriptor]) -> [DependencyConflict] {
        var conflicts: [DependencyConflict] = []
        var exclusiveCapabilities: [SDKModuleCapability: String] = [:]
        let exclusiveCaps: Set<SDKModuleCapability> = [.authentication, .connectorBinding]

        for mod in modules {
            for cap in mod.capabilities where exclusiveCaps.contains(cap) {
                if let existing = exclusiveCapabilities[cap], existing != mod.identifier {
                    conflicts.append(DependencyConflict(
                        moduleA: existing,
                        moduleB: mod.identifier,
                        conflictType: .capabilityCollision,
                        description: "Both '\(existing)' and '\(mod.identifier)' claim exclusive capability '\(cap.rawValue)'"
                    ))
                } else {
                    exclusiveCapabilities[cap] = mod.identifier
                }
            }
        }

        return conflicts
    }
}
