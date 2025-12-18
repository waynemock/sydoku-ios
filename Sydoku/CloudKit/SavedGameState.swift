//
//  SavedGameState.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/18/25.
//

import Foundation
import SwiftData

/// A SwiftData model representing a saved game state synced via CloudKit.
///
/// This model stores the current game progress, allowing users to resume
/// games across devices through CloudKit sync.
@Model
final class SavedGameState {
    /// The current board state (9x9 grid, stored as flat array).
    var boardData: [Int] = []
    
    /// Pencil notes for each cell (stored as JSON data).
    var notesData: Data = Data()
    
    /// The solution board (9x9 grid, stored as flat array).
    var solutionData: [Int] = []
    
    /// The initial puzzle board (9x9 grid, stored as flat array).
    var initialBoardData: [Int] = []
    
    /// The difficulty level of the saved game.
    var difficulty: String = ""
    
    /// Elapsed time in seconds.
    var elapsedTime: TimeInterval = 0.0
    
    /// When the game was started.
    var startDate: Date = Date()
    
    /// Number of mistakes made.
    var mistakes: Int = 0
    
    /// Whether this is a daily challenge.
    var isDailyChallenge: Bool = false
    
    /// The date string for the daily challenge (if applicable).
    var dailyChallengeDate: String? = nil
    
    /// When this game was last saved.
    var lastSaved: Date = Date()
    
    /// Creates a new saved game state.
    init(
        boardData: [Int],
        notesData: Data,
        solutionData: [Int],
        initialBoardData: [Int],
        difficulty: String,
        elapsedTime: TimeInterval,
        startDate: Date,
        mistakes: Int,
        isDailyChallenge: Bool,
        dailyChallengeDate: String?,
        lastSaved: Date = Date()
    ) {
        self.boardData = boardData
        self.notesData = notesData
        self.solutionData = solutionData
        self.initialBoardData = initialBoardData
        self.difficulty = difficulty
        self.elapsedTime = elapsedTime
        self.startDate = startDate
        self.mistakes = mistakes
        self.isDailyChallenge = isDailyChallenge
        self.dailyChallengeDate = dailyChallengeDate
        self.lastSaved = lastSaved
    }
    
    /// Converts a 9x9 2D array to a flat array for storage.
    static func flatten(_ grid: [[Int]]) -> [Int] {
        return grid.flatMap { $0 }
    }
    
    /// Converts a flat array back to a 9x9 2D array.
    static func unflatten(_ data: [Int]) -> [[Int]] {
        var grid: [[Int]] = []
        for i in 0..<9 {
            let start = i * 9
            let end = start + 9
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
            return Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
        }
        return notesArray.map { row in
            row.map { Set($0) }
        }
    }
}
