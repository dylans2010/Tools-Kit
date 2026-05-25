import Foundation

enum ChessPieceType: String {
    case pawn, rook, knight, bishop, queen, king
}

struct ChessPieceModel: Identifiable {
    let id = UUID()
    let type: ChessPieceType
    let isWhite: Bool
}
