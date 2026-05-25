import Foundation

struct SudokuGenerator {
    static func generate() -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillGrid(&grid)
        maskGrid(&grid)
        return grid
    }

    private static func fillGrid(_ grid: inout [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    let numbers = (1...9).shuffled()
                    for num in numbers {
                        if isValid(grid, row, col, num) {
                            grid[row][col] = num
                            if fillGrid(&grid) { return true }
                            grid[row][col] = 0
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
        let startRow = (row / 3) * 3
        let startCol = (col / 3) * 3
        for i in 0..<3 {
            for j in 0..<3 {
                if grid[startRow + i][startCol + j] == num { return false }
            }
        }
        return true
    }

    private static func maskGrid(_ grid: inout [[Int]]) {
        let attempts = 40
        for _ in 0..<attempts {
            let r = Int.random(in: 0..<9)
            let c = Int.random(in: 0..<9)
            grid[r][c] = 0
        }
    }
}
