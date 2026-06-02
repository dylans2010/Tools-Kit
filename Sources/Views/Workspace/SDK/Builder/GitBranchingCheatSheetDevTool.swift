import SwiftUI

struct GitBranchingCheatSheetDevTool: DevTool {
    let id = "git-branching"
    let name = "Git Branching Cheat Sheet"
    let category: DevToolCategory = .automation
    let icon = "arrow.branch"
    let description = "Quick reference for Git branching commands"

    func render() -> some View {
        List {
            Text("git branch -m <newname>: Rename branch")
            Text("git push origin --delete <branch>: Delete remote")
            Text("git checkout -b <branch>: New branch")
            Text("git merge <branch>: Merge branch")
            Text("git rebase <branch>: Rebase branch")
        }
    }
}
