import Foundation
import Foundation
import Combine

class SudokuGame: ObservableObject {
    @Published var board: [[Int]]
    @Published var notes: [[Set<Int>]]
    @Published var solution: [[Int]]
    @Published var initialBoard: [[Int]]
    @Published var selectedCell: (row: Int, col: Int)?
    @Published var isComplete = false
    @Published var hasError = false
    @Published var isGenerating = false
    @Published var isPencilMode = false
    @Published var highlightedNumber: Int?
    @Published var elapsedTime: TimeInterval = 0
    @Published var stats = GameStats()
    @Published var hasSavedGame = false
    @Published var isPaused = false
    @Published var mistakes = 0
    @Published var isGameOver = false
    @Published var settings = GameSettings()
    @Published var lastPlacedCell: (row: Int, col: Int)?
    @Published var showConfetti = false
    @Published var currentHintLevel: HintLevel = .showRegion
    @Published var hintRegion: String?
    @Published var hintNumber: Int?
    @Published var hintCell: (row: Int, col: Int)?
    @Published var isDailyChallenge = false
    @Published var dailyChallengeCompleted = false
    @Published var triggerErrorHaptic = false
    @Published var triggerSuccessHaptic = false
    
    private var undoStack: [GameState] = []
    private var redoStack: [GameState] = []
    private let maxUndoSteps = 50
    private var timer: Timer?
    private var currentDifficulty: Difficulty = .medium
    private var gameStartDate = Date()
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    
    var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) / 60 % 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var mistakesText: String {
        if settings.mistakeLimit == 0 {
            return "Mistakes: \(mistakes)"
        } else {
            return "Mistakes: \(mistakes)/\(settings.mistakeLimit)"
        }
    }
    
    init() {
        board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        notes = Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
        solution = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        initialBoard = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        loadStats()
        loadSettings()
        checkForSavedGame()
    }
    
    // MARK: - Settings
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "gameSettings"),
           let loaded = try? JSONDecoder().decode(GameSettings.self, from: data) {
            settings = loaded
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "gameSettings")
        }
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
            self?.autoSave()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func pauseTimer() {
        stopTimer()
        isPaused = true
    }
    
    func resumeTimer() {
        if !isComplete && !isGenerating && !isGameOver {
            startTimer()
            isPaused = false
        }
    }
    
    func togglePause() {
        if isPaused {
            resumeTimer()
        } else {
            pauseTimer()
        }
    }
    
    // MARK: - Save/Load Game
    private func autoSave() {
        if Int(elapsedTime) % 5 == 0 {
            saveGame()
        }
    }
    
    func saveGame() {
        let saved = SavedGame(
            board: board,
            notes: notes,
            solution: solution,
            initialBoard: initialBoard,
            difficulty: currentDifficulty.rawValue,
            elapsedTime: elapsedTime,
            startDate: gameStartDate,
            mistakes: mistakes
        )
        
        if let encoded = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(encoded, forKey: "savedGame")
            hasSavedGame = true
        }
    }
    
    func loadSavedGame() {
        guard let data = UserDefaults.standard.data(forKey: "savedGame"),
              let saved = try? JSONDecoder().decode(SavedGame.self, from: data),
              let difficulty = Difficulty(rawValue: saved.difficulty) else {
            return
        }
        
        board = saved.board
        notes = saved.notes
        solution = saved.solution
        initialBoard = saved.initialBoard
        currentDifficulty = difficulty
        elapsedTime = saved.elapsedTime
        gameStartDate = saved.startDate
        mistakes = saved.mistakes
        isComplete = false
        hasError = false
        isGameOver = false
        selectedCell = nil
        undoStack.removeAll()
        redoStack.removeAll()
        highlightedNumber = nil
        
        startTimer()
    }
    
    func deleteSavedGame() {
        UserDefaults.standard.removeObject(forKey: "savedGame")
        hasSavedGame = false
    }
    
    private func checkForSavedGame() {
        hasSavedGame = UserDefaults.standard.data(forKey: "savedGame") != nil
    }
    
    // MARK: - Statistics
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: "gameStats"),
           let loaded = try? JSONDecoder().decode(GameStats.self, from: data) {
            stats = loaded
        }
    }
    
    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: "gameStats")
        }
    }
    
    func resetStats() {
        stats = GameStats()
        saveStats()
    }
    
    // MARK: - Undo/Redo
    private func saveState() {
        let state = GameState(board: board, notes: notes, mistakes: mistakes)
        undoStack.append(state)
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }
    
    func undo() {
        guard !undoStack.isEmpty else { return }
        let currentState = GameState(board: board, notes: notes, mistakes: mistakes)
        redoStack.append(currentState)
        
        let previousState = undoStack.removeLast()
        board = previousState.board
        notes = previousState.notes
        mistakes = previousState.mistakes
        checkCompletion()
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        let currentState = GameState(board: board, notes: notes, mistakes: mistakes)
        undoStack.append(currentState)
        
        let nextState = redoStack.removeLast()
        board = nextState.board
        notes = nextState.notes
        mistakes = nextState.mistakes
        checkCompletion()
    }
    
    // MARK: - Puzzle Generation
    func generatePuzzle(difficulty: Difficulty, seed: Int? = nil) {
        stopTimer()
        isGenerating = true
        currentDifficulty = difficulty
        isDailyChallenge = false
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if let seed = seed {
                var generator = SeededRandomNumberGenerator(seed: seed)
                var newSolution = Array(repeating: Array(repeating: 0, count: 9), count: 9)
                self.fillBoard(&newSolution, using: &generator)
                let newBoard = self.removeNumbersWithUniqueness(from: newSolution, count: difficulty.cellsToRemove, using: &generator)
                
                DispatchQueue.main.async {
                    self.finalizePuzzleGeneration(solution: newSolution, board: newBoard, difficulty: difficulty)
                }
            } else {
                var newSolution = Array(repeating: Array(repeating: 0, count: 9), count: 9)
                self.fillBoard(&newSolution)
                let newBoard = self.removeNumbersWithUniqueness(from: newSolution, count: difficulty.cellsToRemove)
                
                DispatchQueue.main.async {
                    self.finalizePuzzleGeneration(solution: newSolution, board: newBoard, difficulty: difficulty)
                }
            }
        }
    }
    
    private func finalizePuzzleGeneration(solution: [[Int]], board: [[Int]], difficulty: Difficulty) {
        self.solution = solution
        self.board = board
        self.notes = Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
        self.initialBoard = board
        self.isComplete = false
        self.hasError = false
        self.isGenerating = false
        self.isGameOver = false
        self.selectedCell = nil
        self.undoStack.removeAll()
        self.redoStack.removeAll()
        self.highlightedNumber = nil
        self.elapsedTime = 0
        self.gameStartDate = Date()
        self.isPaused = false
        self.mistakes = 0
        self.showConfetti = false
        
        self.stats.recordStart(difficulty: difficulty.rawValue)
        self.saveStats()
        self.deleteSavedGame()
        self.startTimer()
    }
    
    // MARK: - Seeded Random Number Generator
    struct SeededRandomNumberGenerator: RandomNumberGenerator {
        private var state: UInt64
        
        init(seed: Int) {
            self.state = UInt64(abs(seed))
        }
        
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }
    
    // MARK: - Board Filling
    @discardableResult
    private func fillBoard(_ grid: inout [[Int]], using generator: inout SeededRandomNumberGenerator) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    let nums = (1...9).shuffled(using: &generator)
                    for num in nums {
                        if isValid(grid, row, col, num) {
                            grid[row][col] = num
                            if fillBoard(&grid, using: &generator) {
                                return true
                            }
                            grid[row][col] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }
    
    @discardableResult
    private func fillBoard(_ grid: inout [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    let nums = (1...9).shuffled()
                    for num in nums {
                        if isValid(grid, row, col, num) {
                            grid[row][col] = num
                            if fillBoard(&grid) {
                                return true
                            }
                            grid[row][col] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }
    
    private func removeNumbersWithUniqueness(from solution: [[Int]], count: Int, using generator: inout SeededRandomNumberGenerator) -> [[Int]] {
        var puzzle = solution
        var positions = [(Int, Int)]()
        
        for r in 0..<9 {
            for c in 0..<9 {
                positions.append((r, c))
            }
        }
        positions.shuffle(using: &generator)
        
        var removed = 0
        var attempts = 0
        let maxAttempts = 81 * 2
        
        for (r, c) in positions {
            if removed >= count { break }
            if attempts >= maxAttempts { break }
            
            attempts += 1
            let backup = puzzle[r][c]
            puzzle[r][c] = 0
            
            if hasUniqueSolution(puzzle) {
                removed += 1
            } else {
                puzzle[r][c] = backup
            }
        }
        
        return puzzle
    }
    
    private func removeNumbersWithUniqueness(from solution: [[Int]], count: Int) -> [[Int]] {
        var puzzle = solution
        var positions = [(Int, Int)]()
        
        for r in 0..<9 {
            for c in 0..<9 {
                positions.append((r, c))
            }
        }
        positions.shuffle()
        
        var removed = 0
        var attempts = 0
        let maxAttempts = 81 * 2
        
        for (r, c) in positions {
            if removed >= count { break }
            if attempts >= maxAttempts { break }
            
            attempts += 1
            let backup = puzzle[r][c]
            puzzle[r][c] = 0
            
            if hasUniqueSolution(puzzle) {
                removed += 1
            } else {
                puzzle[r][c] = backup
            }
        }
        
        return puzzle
    }
    
    private func hasUniqueSolution(_ grid: [[Int]]) -> Bool {
        var testGrid = grid
        var solutionCount = 0
        countSolutions(&testGrid, &solutionCount, maxCount: 2)
        return solutionCount == 1
    }
    
    private func countSolutions(_ grid: inout [[Int]], _ count: inout Int, maxCount: Int) {
        if count >= maxCount { return }
        
        var emptyRow = -1
        var emptyCol = -1
        
        outer: for r in 0..<9 {
            for c in 0..<9 {
                if grid[r][c] == 0 {
                    emptyRow = r
                    emptyCol = c
                    break outer
                }
            }
        }
        
        if emptyRow == -1 {
            count += 1
            return
        }
        
        for num in 1...9 {
            if isValid(grid, emptyRow, emptyCol, num) {
                grid[emptyRow][emptyCol] = num
                countSolutions(&grid, &count, maxCount: maxCount)
                grid[emptyRow][emptyCol] = 0
                
                if count >= maxCount { return }
            }
        }
    }
    
    func isValid(_ grid: [[Int]], _ row: Int, _ col: Int, _ num: Int) -> Bool {
        for c in 0..<9 {
            if grid[row][c] == num { return false }
        }
        
        for r in 0..<9 {
            if grid[r][col] == num { return false }
        }
        
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<boxRow + 3 {
            for c in boxCol..<boxCol + 3 {
                if grid[r][c] == num { return false }
            }
        }
        
        return true
    }
    
    // MARK: - Game Actions
    func setNumber(_ num: Int) {
        guard let cell = selectedCell else { return }
        if initialBoard[cell.row][cell.col] == 0 {
            saveState()
            
            if isPencilMode {
                if notes[cell.row][cell.col].contains(num) {
                    notes[cell.row][cell.col].remove(num)
                } else {
                    notes[cell.row][cell.col].insert(num)
                }
            } else {
                board[cell.row][cell.col] = num
                notes[cell.row][cell.col].removeAll()
                lastPlacedCell = cell
                
                if settings.autoErrorChecking && num != solution[cell.row][cell.col] {
                    mistakes += 1
                    if settings.hapticFeedback {
                        triggerErrorHaptic.toggle()
                    }
                    
                    if settings.mistakeLimit > 0 && mistakes >= settings.mistakeLimit {
                        isGameOver = true
                        stopTimer()
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.lastPlacedCell = nil
                }
                
                checkCompletion()
            }
        }
    }
    
    func clearCell() {
        guard let cell = selectedCell else { return }
        if initialBoard[cell.row][cell.col] == 0 {
            saveState()
            board[cell.row][cell.col] = 0
            notes[cell.row][cell.col].removeAll()
            hasError = false
            isComplete = false
        }
    }
    
    func autoFillNotes() {
        saveState()
        for r in 0..<9 {
            for c in 0..<9 {
                if board[r][c] == 0 && initialBoard[r][c] == 0 {
                    notes[r][c].removeAll()
                    for num in 1...9 {
                        if isValid(board, r, c, num) {
                            notes[r][c].insert(num)
                        }
                    }
                }
            }
        }
    }
    
    func checkCompletion() {
        for row in board {
            if row.contains(0) {
                isComplete = false
                return
            }
        }
        
        hasError = false
        for r in 0..<9 {
            for c in 0..<9 {
                if board[r][c] != solution[r][c] {
                    hasError = true
                    return
                }
            }
        }
        
        isComplete = true
        showConfetti = true
        stopTimer()
        stats.recordWin(difficulty: currentDifficulty.rawValue, time: elapsedTime)
        saveStats()
        deleteSavedGame()
        if settings.hapticFeedback {
            triggerSuccessHaptic.toggle()
        }
        
        if isDailyChallenge {
            let dateString = DailyChallenge.getDateString(for: Date())
            settings.lastDailyPuzzleDate = dateString
            dailyChallengeCompleted = true
            saveSettings()
        }
    }
    
    func getConflicts(row: Int, col: Int) -> Bool {
        if !settings.autoErrorChecking { return false }
        
        let num = board[row][col]
        if num == 0 { return false }
        
        return board[row][col] != solution[row][col]
    }
    
    // MARK: - Hints
    func giveHint() {
        var emptyCells = [(Int, Int)]()
        for r in 0..<9 {
            for c in 0..<9 {
                if board[r][c] == 0 {
                    emptyCells.append((r, c))
                }
            }
        }
        
        guard let randomCell = emptyCells.randomElement() else { return }
        let targetRow = randomCell.0
        let targetCol = randomCell.1
        let targetNum = solution[targetRow][targetCol]
        
        switch currentHintLevel {
        case .showRegion:
            let regions = ["row \(targetRow + 1)", "column \(targetCol + 1)", "box"]
            hintRegion = regions.randomElement()
            hintNumber = nil
            hintCell = nil
            currentHintLevel = .showNumber
            
        case .showNumber:
            hintRegion = nil
            hintNumber = targetNum
            hintCell = nil
            currentHintLevel = .highlightCell
            
        case .highlightCell:
            hintRegion = nil
            hintNumber = nil
            hintCell = randomCell
            selectedCell = randomCell
            currentHintLevel = .revealAnswer
            
        case .revealAnswer:
            saveState()
            board[targetRow][targetCol] = solution[targetRow][targetCol]
            initialBoard[targetRow][targetCol] = solution[targetRow][targetCol]
            notes[targetRow][targetCol].removeAll()
            hintRegion = nil
            hintNumber = nil
            hintCell = nil
            currentHintLevel = .showRegion
            checkCompletion()
        }
    }
    
    func resetHints() {
        currentHintLevel = .showRegion
        hintRegion = nil
        hintNumber = nil
        hintCell = nil
    }
    
    // MARK: - Daily Challenge
    func generateDailyChallenge() {
        let today = Date()
        let seed = DailyChallenge.getSeed(for: today)
        let dateString = DailyChallenge.getDateString(for: today)
        
        if settings.lastDailyPuzzleDate == dateString {
            dailyChallengeCompleted = true
        } else {
            dailyChallengeCompleted = false
        }
        
        isDailyChallenge = true
        generatePuzzle(difficulty: .medium, seed: seed)
    }
    
    // MARK: - Puzzle Code
    func getPuzzleCode() -> String {
        var code = ""
        for row in initialBoard {
            for num in row {
                code += "\(num)"
            }
        }
        return code
    }
    
    func loadFromCode(_ code: String) -> Bool {
        guard code.count == 81 else { return false }
        
        var newBoard = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        var index = 0
        
        for r in 0..<9 {
            for c in 0..<9 {
                let char = code[code.index(code.startIndex, offsetBy: index)]
                if let num = Int(String(char)), num >= 0 && num <= 9 {
                    newBoard[r][c] = num
                } else {
                    return false
                }
                index += 1
            }
        }
        
        var solutionBoard = newBoard
        if !solvePuzzle(&solutionBoard) {
            return false
        }
        
        board = newBoard
        initialBoard = newBoard
        solution = solutionBoard
        notes = Array(repeating: Array(repeating: Set<Int>(), count: 9), count: 9)
        mistakes = 0
        elapsedTime = 0
        isComplete = false
        isGameOver = false
        isDailyChallenge = false
        
        startTimer()
        return true
    }
    
    private func solvePuzzle(_ grid: inout [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    for num in 1...9 {
                        if isValid(grid, row, col, num) {
                            grid[row][col] = num
                            if solvePuzzle(&grid) {
                                return true
                            }
                            grid[row][col] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }
    
    func getNumberCount(_ num: Int) -> Int {
        var count = 0
        for r in 0..<9 {
            for c in 0..<9 {
                if board[r][c] == num {
                    count += 1
                }
            }
        }
        return count
    }
}
