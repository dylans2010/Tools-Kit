import Foundation

struct SudokuGenerator {
    static func generate(difficulty: Int) -> (puzzle: [[Int]], solution: [[Int]]) {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillGrid(&grid)
        let solution = grid
        let cellsToRemove: Int
        switch difficulty {
        case 0: cellsToRemove = 35
        case 1: cellsToRemove = 45
        default: cellsToRemove = 55
        }
        var positions = (0..<81).map { ($0 / 9, $0 % 9) }.shuffled()
        var removed = 0
        while removed < cellsToRemove && !positions.isEmpty {
            let (r, c) = positions.removeFirst()
            if grid[r][c] != 0 { grid[r][c] = 0; removed += 1 }
        }
        return (puzzle: grid, solution: solution)
    }

    private static func fillGrid(_ grid: inout [[Int]]) -> Bool {
        for r in 0..<9 {
            for c in 0..<9 {
                if grid[r][c] == 0 {
                    for num in (1...9).shuffled() {
                        if isValid(grid, r, c, num) {
                            grid[r][c] = num
                            if fillGrid(&grid) { return true }
                            grid[r][c] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }

    private static func isValid(_ grid: [[Int]], _ row: Int, _ col: Int, _ num: Int) -> Bool {
        for i in 0..<9 {
            if grid[row][i] == num || grid[i][col] == num { return false }
        }
        let boxR = (row / 3) * 3, boxC = (col / 3) * 3
        for r in boxR..<boxR+3 {
            for c in boxC..<boxC+3 {
                if grid[r][c] == num { return false }
            }
        }
        return true
    }
}
