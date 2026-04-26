import Foundation

struct AgentCodeDiffEngine {
    func changedLines(old: String, new: String) -> [Int] {
        let oldLines = old.split(separator: "
", omittingEmptySubsequences: false).map(String.init)
        let newLines = new.split(separator: "
", omittingEmptySubsequences: false).map(String.init)
        let maxCount = max(oldLines.count, newLines.count)
        return (0..<maxCount).filter { idx in
            let a = idx < oldLines.count ? oldLines[idx] : ""
            let b = idx < newLines.count ? newLines[idx] : ""
            return a != b
        }
    }
}
