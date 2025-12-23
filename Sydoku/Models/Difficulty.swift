//
//  Difficulty.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/17/25.
//


import Foundation

/// Represents the difficulty level of a Sudoku puzzle.
///
/// Each difficulty level determines how many cells are removed from a completed puzzle,
/// which directly affects how challenging the puzzle is to solve.
enum Difficulty: String, Codable, CaseIterable, Hashable {
    /// Easy difficulty - suitable for beginners.
    case easy
    
    /// Medium difficulty - for intermediate players.
    case medium
    
    /// Hard difficulty - challenging for experienced players.
    case hard
    
    /// The number of clues (pre-filled cells) provided for this difficulty level.
    ///
    /// - Easy: 40 clues
    /// - Medium: 32 clues
    /// - Hard: 26 clues
    var numberOfClues: Int {
        switch self {
        case .easy: return 36
        case .medium: return 32
        case .hard: return 26
        }
    }
    
    /// The number of cells to remove from a completed puzzle for this difficulty level.
    ///
    /// Computed as total cells minus the number of clues.
    var cellsToRemove: Int {
        return SudokuGame.numberOfCells - numberOfClues
    }
    
    /// A human-readable display name for the difficulty level.
    var name: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
 }
