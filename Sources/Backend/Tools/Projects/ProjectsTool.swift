import SwiftUI

struct ProjectsTool: Tool {
    let name = "Projects"
    let icon = "folder.badge.plus"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Plan, organize and collaborate on projects"
    let requiresAPI = false
    var view: AnyView { AnyView(ProjectsMainView()) }
}
