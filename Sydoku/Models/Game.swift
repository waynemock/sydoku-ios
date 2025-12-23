//
//  Game.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/21/25.
//

import Foundation
import SwiftData

/// A SwiftData model representing a game (in-progress or completed).
///
/// This unified model stores both active games and completed game history,
/// allowing users to resume in-progress games and view their game history.
/// Games are synced via CloudKit.
@Model
final class Game {
    
    /// The initial puzzle board (9x9 grid, stored as flat array).
    var initialBoardData: [Int] = []
    
    /// The solution board (9x9 grid, stored as flat array).
    var solutionData: [Int] = []
    
    /// The current/final board state (9x9 grid, stored as flat array).
    var boardData: [Int] = []
    
    /// Pencil notes for each cell (stored as JSON data). Empty for completed games.
    var notesData: Data = Data()
    
    /// The difficulty level of the game.
    var difficulty: String = ""
    
    /// Elapsed/completion time in seconds.
    var elapsedTime: TimeInterval = 0.0
    
    /// When the game was started.
    var startDate: Date = Date()
    
    /// Number of mistakes made.
    var mistakes: Int = 0
    
    /// The cells that had hints (9x9 grid, stored as flat array).
    var hintsData: [Int] = []
    
    /// Number of hints used (computed from hintsData).
    var hintsUsed: Int {
        return hintsData.filter { $0 == 1 }.count
    }
    
    /// Whether this was a daily challenge.
    var isDailyChallenge: Bool = false
    
    /// The date string for the daily challenge (if applicable).
    var dailyChallengeDate: String? = nil
    
    /// Whether the game has been completed.
    var isCompleted: Bool = false
    
    /// When the game was completed (nil for in-progress games).
    var completionDate: Date? = nil
    
    /// When this game was last saved/updated.
    var lastSaved: Date = Date()
    
    /// A unique identifier for CloudKit sync.
    /// Note: We don't use @Attribute(.unique) because CloudKit doesn't support unique constraints.
    var gameID: String = UUID().uuidString
    
    // MARK: - UI State (for seamless resume)
    
    /// The selected cell row (nil if no selection). Only used for in-progress games.
    var selectedCellRow: Int? = nil
    
    /// The selected cell column (nil if no selection). Only used for in-progress games.
    var selectedCellCol: Int? = nil
    
    /// The currently highlighted number (nil if none). Only used for in-progress games.
    var highlightedNumber: Int? = nil
    
    /// Whether pencil mode is active. Only used for in-progress games.
    var isPencilMode: Bool = false
    
    /// Whether the game was paused when saved. Only used for in-progress games.
    var wasPaused: Bool = false
    
    // MARK: - Undo/Redo State (for seamless resume)
    
    /// The undo stack serialized as JSON data. Only used for in-progress games.
    var undoStackData: Data = Data()
    
    /// The redo stack serialized as JSON data. Only used for in-progress games.
    var redoStackData: Data = Data()
    
    /// Creates a new game record.
    ///
    /// - Parameters:
    ///   - initialBoardData: The initial puzzle board.
    ///   - solutionData: The solution board.
    ///   - boardData: Current board state.
    ///   - notesData: Pencil notes (empty for completed games).
    ///   - difficulty: Difficulty level.
    ///   - elapsedTime: Time elapsed/completion time.
    ///   - startDate: When the game started.
    ///   - mistakes: Number of mistakes.
    ///   - hintsData: Grid of hint indicators.
    ///   - isDailyChallenge: Whether this is a daily challenge.
    ///   - dailyChallengeDate: Date string for daily challenges.
    ///   - isCompleted: Whether the game is completed.
    ///   - completionDate: When completed (nil for in-progress).
    ///   - lastSaved: Last save timestamp.
    ///   - gameID: Unique identifier.
    ///   - selectedCellRow: Selected cell row (for resume).
    ///   - selectedCellCol: Selected cell column (for resume).
    ///   - highlightedNumber: Highlighted number (for resume).
    ///   - isPencilMode: Pencil mode state (for resume).
    ///   - wasPaused: Paused state (for resume).
    ///   - undoStackData: Serialized undo stack (for resume).
    ///   - redoStackData: Serialized redo stack (for resume).
    init(
        initialBoardData: [Int],
        solutionData: [Int],
        boardData: [Int],
        notesData: Data = Data(),
        difficulty: String,
        elapsedTime: TimeInterval,
        startDate: Date,
        mistakes: Int,
        hintsData: [Int],
        isDailyChallenge: Bool,
        dailyChallengeDate: String?,
        isCompleted: Bool = false,
        completionDate: Date? = nil,
        lastSaved: Date = Date(),
        gameID: String = UUID().uuidString,
        selectedCellRow: Int? = nil,
        selectedCellCol: Int? = nil,
        highlightedNumber: Int? = nil,
        isPencilMode: Bool = false,
        wasPaused: Bool = false,
        undoStackData: Data = Data(),
        redoStackData: Data = Data()
    ) {
        self.initialBoardData = initialBoardData
        self.solutionData = solutionData
        self.boardData = boardData
        self.notesData = notesData
        self.difficulty = difficulty
        self.elapsedTime = elapsedTime
        self.startDate = startDate
        self.mistakes = mistakes
        self.hintsData = hintsData
        self.isDailyChallenge = isDailyChallenge
        self.dailyChallengeDate = dailyChallengeDate
        self.isCompleted = isCompleted
        self.completionDate = completionDate
        self.lastSaved = lastSaved
        self.gameID = gameID
        self.selectedCellRow = selectedCellRow
        self.selectedCellCol = selectedCellCol
        self.highlightedNumber = highlightedNumber
        self.isPencilMode = isPencilMode
        self.wasPaused = wasPaused
        self.undoStackData = undoStackData
        self.redoStackData = redoStackData
    }
    
    /// Converts a 9x9 2D array to a flat array for storage.
    static func flatten(_ grid: [[Int]]) -> [Int] {
        return grid.flatMap { $0 }
    }
    
    /// Converts a flat array back to a 9x9 2D array.
    static func unflatten(_ data: [Int]) -> [[Int]] {
        guard data.count == SudokuGame.numberOfCells else {
            return Array(repeating: Array(repeating: 0, count: SudokuGame.size), count: SudokuGame.size)
        }
        var grid: [[Int]] = []
        for i in 0..<SudokuGame.size {
            let start = i * SudokuGame.size
            let end = start + SudokuGame.size
            grid.append(Array(data[start..<end]))
        }
        return grid
    }
    
    /// Encodes notes (9x9 grid of sets) to Data.
    static func encodeNotes(_ notes: [[Set<Int>]]) -> Data {
        let notesArray = notes.map { row in
            row.map { Array($0) }
        }
        return (try? JSONEncoder().encode(notesArray)) ?? Data()
    }
    
    /// Decodes notes Data back to a 9x9 grid of sets.
    static func decodeNotes(_ data: Data) -> [[Set<Int>]] {
        guard let notesArray = try? JSONDecoder().decode([[[Int]]].self, from: data) else {
            return Array(repeating: Array(repeating: Set<Int>(), count: SudokuGame.size), count: SudokuGame.size)
        }
        return notesArray.map { row in
            row.map { Set($0) }
        }
    }
    
    /// Encodes an undo/redo stack to Data.
    static func encodeGameStateStack(_ stack: [GameState]) -> Data {
        return (try? JSONEncoder().encode(stack)) ?? Data()
    }
    
    /// Decodes an undo/redo stack from Data.
    static func decodeGameStateStack(_ data: Data) -> [GameState] {
        guard !data.isEmpty else { return [] }
        return (try? JSONDecoder().decode([GameState].self, from: data)) ?? []
    }
}
