import Foundation
import Foundation
import Combine

/// The main game controller for Sudoku gameplay.
///
/// `SudokuGame` manages all aspects of the Sudoku game including the board state,
/// puzzle generation, user interactions, timer, statistics, undo/redo, hints,
/// daily challenges, and game settings.
class SudokuGame: ObservableObject {
    static let size: Int = 9
    static let numberOfCells = size * size
    
    // MARK: - Published Properties
    
    // MARK: Board State
    /// The current state of the game board (9x9 grid).
    @Published var board: [[Int]]
    
    /// The initial puzzle state with given numbers (9x9 grid).
    @Published var initialBoard: [[Int]]

    /// Whether the board has been generated (at least one cell is non-zero).
    var hasBoardBeenGenerated: Bool {
        !initialBoard.allSatisfy { $0.allSatisfy { $0 == 0 } }
    }

    /// The solution to the current puzzle (9x9 grid).
    @Published var solution: [[Int]]
    
    /// Pencil mark notes for each cell (9x9 grid of sets).
    @Published var notes: [[Set<Int>]]
    
    /// The number of hints taken in the current game.
    @Published var hints: [[Int]]
    
    // MARK: Game State
    /// Whether a new puzzle is currently being generated.
    @Published var isGenerating = false
    
    /// Whether the puzzle has been completed successfully.
    @Published var isComplete = false
    
    /// Whether the current board has any rule violations.
    @Published var hasError = false
    
    /// Whether the game has ended (e.g., reached mistake limit).
    @Published var isMistakeLimitReached = false

    /// Whether the game is currently paused.
    @Published var isPaused = false
    
    /// Whether an in-progress game exists that can be resumed.
    @Published var hasInProgressGame = false
    
    // MARK: UI State
    /// The currently selected cell coordinates, or `nil` if no cell is selected.
    @Published var selectedCell: (row: Int, col: Int)?
    
    /// The coordinates of the most recently placed number.
    @Published var lastPlacedCell: (row: Int, col: Int)?
    
    /// The number currently highlighted on the board, or `nil` if none.
    @Published var highlightedNumber: Int?
    
    /// Whether pencil mode is active for entering notes.
    @Published var isPencilMode = false
    
    /// Whether to show the confetti celebration animation.
    @Published var showConfetti = false
    
    // MARK: Game Progress
    /// The elapsed time for the current game in seconds.
    @Published var elapsedTime: TimeInterval = 0
    
    /// The number of mistakes made in the current game.
    @Published var mistakes = 0
    
    // MARK: Daily Challenge
    /// Whether the current game is a daily challenge.
    @Published var isDailyChallenge = false
    
    /// The date string of the current daily challenge (if applicable).
    var dailyChallengeDate: String?
    
    /// Whether today's daily challenge has been completed.
    @Published var dailyChallengeCompleted = false
    
    /// Whether the saved daily challenge is from a previous day.
    var isDailyChallengeExpired: Bool {
        guard isDailyChallenge, let savedDate = dailyChallengeDate else {
            return false
        }
        let todayString = DailyChallenge.getDateString(for: Date())
        return savedDate != todayString
    }
    
    // MARK: Settings & Stats
    /// Game settings and preferences.
    @Published var settings = GameSettings()
    
    /// Statistics tracking performance across games.
    @Published var stats = GameStats()
    
    // MARK: Haptics
    /// Triggers haptic feedback for errors when toggled.
    @Published var triggerErrorHaptic = false
    
    /// Triggers haptic feedback for successful actions when toggled.
    @Published var triggerSuccessHaptic = false
    
    // MARK: - Private Properties
    
    /// Stack of previous game states for undo functionality.
    var undoStack: [GameState] = []
    
    /// Stack of undone game states for redo functionality.
    var redoStack: [GameState] = []
    
    /// Maximum number of undo steps to maintain.
    private let maxUndoSteps = 50
    
    /// Timer for tracking elapsed game time.
    private var timer: Timer?
    
    /// Debounce timer for auto-saving after user actions.
    private var saveDebounceTimer: Timer?
    
    /// The difficulty level of the current puzzle.
    var currentDifficulty: Difficulty = .medium
    
    /// The date and time when the current game started.
    var gameStartDate = Date()
    
    /// The unique identifier for the current game (for tracking across saves).
    var currentGameID: String?
    
    /// Persistence service for SwiftData operations.
    private var persistenceService: PersistenceService?
    
    /// SwiftData model for game statistics.
    private var statsModel: GameStatistics?
    
    /// SwiftData model for user settings.
    private var settingsModel: UserSettings?
    
    /// Logger for game events.
    private let logger = AppLogger(category: "SudokuGame")
    
    // MARK: - Computed Properties
    
    /// The current puzzle's difficulty level.
    var difficulty: Difficulty {
        currentDifficulty
    }
    
    /// Whether an undo operation is available.
    var canUndo: Bool { !undoStack.isEmpty }
    
    /// Whether a redo operation is available.
    var canRedo: Bool { !redoStack.isEmpty }
    
    /// The elapsed time formatted as a string (HH:MM:SS or MM:SS).
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
    
    /// The mistakes counter formatted as a string with optional limit.
    var mistakesText: String {
        if settings.mistakeLimit == 0 {
            return "Mistakes: \(mistakes)"
        } else {
            return "Mistakes: \(mistakes)/\(settings.mistakeLimit)"
        }
    }
    
    // MARK: - Initialization
    
    /// Initializes a new Sudoku game with empty boards.
    ///
    /// The persistence service should be configured after initialization
    /// by calling `configurePersistence(persistenceService:)`.
    init() {
        board = Array(repeating: Array(repeating: 0, count: SudokuGame.size), count: SudokuGame.size)
        notes = Array(repeating: Array(repeating: Set<Int>(), count: SudokuGame.size), count: SudokuGame.size)
        solution = Array(repeating: Array(repeating: 0, count: SudokuGame.size), count: SudokuGame.size)
        initialBoard = Array(repeating: Array(repeating: 0, count: SudokuGame.size), count: SudokuGame.size)
        hints = Array(repeating: Array(repeating: 0, count: SudokuGame.size), count: SudokuGame.size)
    }
    
    // MARK: - Persistence Configuration
    
    /// Configures the persistence service and loads data from SwiftData.
    ///
    /// This should be called once after initialization, typically in the view's `onAppear`.
    ///
    /// - Parameter persistenceService: The persistence service to use for data operations.
    func configurePersistence(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
        
        // Load statistics
        statsModel = persistenceService.fetchOrCreateStatistics()
        stats = StatsAdapter.toStruct(from: statsModel!)
        
        // Load settings
        settingsModel = persistenceService.fetchOrCreateSettings()
        settings = SettingsAdapter.toStruct(from: settingsModel!)
        
        // IMPORTANT: Sync from CloudKit first, then check for saved game
        // This ensures we don't load stale data that's been completed on another device
        Task {
            await syncAllFromCloudKit()
            
            // After sync completes, if no game was found in CloudKit, check local
            // (This handles the offline case where we might have local data)
            if !hasInProgressGame {
                await MainActor.run {
                    checkForSavedGame()
                }
            }
        }
    }
    
    /// Reloads data from persistence (useful when app returns to foreground).
    ///
    /// This refreshes statistics, settings, and checks for updated saved games
    /// that may have synced from CloudKit while the app was backgrounded.
    func reloadFromPersistence() {
        guard persistenceService != nil else { return }
        
        Task {
            await syncAllFromCloudKit()
        }
    }
    
    /// Syncs all data (settings, statistics, saved game) from CloudKit.
    ///
    /// This is the central sync method that should be called when the app launches
    /// or returns to foreground. If we have a currentGameID, it efficiently syncs
    /// just that game. Otherwise, it looks for any in-progress games.
    func syncAllFromCloudKit() async {
        guard let persistenceService = persistenceService else { return }
        
        // Cancel any pending debounced saves to prevent overwriting CloudKit data
        await MainActor.run {
            saveDebounceTimer?.invalidate()
            saveDebounceTimer = nil
        }
        
        // Get the current game ID if we have one
        let gameID = await MainActor.run { currentGameID }
        
        // Sync the game state
        if let gameID = gameID, !gameID.isEmpty {
            // We have a current game - sync that specific game
            logger.info(self, "Syncing specific game (gameID: \(gameID))")
            let (syncedGame, wasCompleted) = await persistenceService.syncGameFromCloudKit(gameID: gameID)
            
            if wasCompleted {
                // Game was completed on another device - load the completed state
                if let game = syncedGame {
                    await MainActor.run {
                        logger.info(self, "Current game was completed on another device")
                        
                        // Load the completed board state (but clear notes since it's completed)
                        loadGame(from: game, clearUIState: true)
                    }
                }
                
                // After detecting completion, check if there's a NEW game from another device
                // (The other device may have already started a new game)
                logger.info(self, "Checking for new games after completion...")
                if let newGame = await persistenceService.syncInProgressGameFromCloudKit() {
                    // There's a new game - load it immediately
                    await MainActor.run {
                        logger.info(self, "New game detected after completion, loading it (gameID: \(newGame.gameID))")
                        
                        // Load the new in-progress game
                        loadGame(from: newGame)

                        logger.info(self, "New game loaded from CloudKit (paused: \(isPaused))")
                    }
                }
            } else if let game = syncedGame {
                // Game is still in progress - update UI with latest state
                await MainActor.run {
                    // Load the game state
                    loadGame(from: game)
                    
                    logger.info(self, "Game reloaded from CloudKit (paused: \(isPaused))")
                }
            } else {
                // Game not found in CloudKit - it was deleted or doesn't exist
                await MainActor.run {
                    logger.info(self, "Current game not found in CloudKit (gameID: \(gameID))")
                    hasInProgressGame = false
                    currentGameID = nil
                }
            }
        } else {
            // No current game - look for any in-progress games
            logger.info(self, "No current game, checking for any in-progress games")
            if let freshSavedGame = await persistenceService.syncInProgressGameFromCloudKit() {
                // Found an in-progress game - load it
                await MainActor.run {

                    // Load the in-progress game
                    loadGame(from: freshSavedGame)

                    logger.info(self, "Game reloaded from CloudKit (paused: \(isPaused))")
                }
            } else {
                // No in-progress games found
                await MainActor.run {
                    hasInProgressGame = false
                    logger.info(self, "No in-progress game found in CloudKit")
                }
            }
        }
        
        // Download latest settings from CloudKit
        if let freshSettings = await persistenceService.syncSettingsFromCloudKit() {
            await MainActor.run {
                settingsModel = freshSettings
                settings = SettingsAdapter.toStruct(from: freshSettings)
                logger.info(self, "Settings reloaded from CloudKit")
            }
        }
        
        // Download latest statistics from CloudKit
        if let freshStatistics = await persistenceService.syncStatisticsFromCloudKit() {
            await MainActor.run {
                statsModel = freshStatistics
                stats = StatsAdapter.toStruct(from: freshStatistics)
                logger.info(self, "Statistics reloaded from CloudKit")
            }
        }
        
        // Download completed games from CloudKit (for game history)
        await persistenceService.syncCompletedGamesFromCloudKit()
    }
    
    // MARK: - Settings
    
    /// Saves current game settings to persistent storage.
    func saveSettings() {
        guard let settingsModel = settingsModel else { return }
        SettingsAdapter.updateModel(settingsModel, from: settings)
        persistenceService?.saveSettings(settingsModel)
    }
    
    // MARK: - Timer Management
    
    /// Starts the game timer, updating elapsed time every second.
    func startTimer() {
        logger.debug(self, "startTimer() called - hasBoardBeenGenerated: \(hasBoardBeenGenerated), isPaused: \(isPaused), solution.isEmpty: \(solution.isEmpty)")
        
        // Don't start timer if no puzzle exists yet
        guard hasBoardBeenGenerated else {
            logger.info(self, "Prevented timer start - board not generated yet")
            return
        }
        
        // Don't start timer if game is paused
        guard !isPaused else {
            logger.info(self, "Prevented timer start - game is paused")
            return
        }
        
        stopTimer()
        
        // Ensure timer is created on the main run loop
        timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Double-check pause state on each tick (in case sync changed it)
            if self.isPaused {
                self.stopTimer()
                self.logger.info(self, "Timer stopped - game was paused")
                return
            }
            self.elapsedTime += 1
        }
        
        // Add to main run loop with common modes so it runs during UI interactions
        RunLoop.main.add(timer!, forMode: .common)
        
        logger.info(self, "Timer started successfully - timer object: \(String(describing: timer))")
    }
    
    /// Stops the game timer.
    func stopTimer() {
        if timer != nil {
            logger.debug(self, "Timer stopped and invalidated")
        }
        timer?.invalidate()
        timer = nil
    }
    
    /// Pauses the game timer.
    func pauseTimer() {
        stopTimer()
        isPaused = true
        
        // Cancel any pending debounced saves to ensure pause state is saved immediately
        saveDebounceTimer?.invalidate()
        saveDebounceTimer = nil
        
        logger.info(self, "Game paused - saving state (isPaused: \(isPaused))")
        saveGame() // Save when pausing
    }
    
    /// Resumes the game timer if the game is in progress.
    func resumeTimer() {
        logger.info(self, "resumeTimer() called - isComplete: \(isComplete), isGenerating: \(isGenerating), isMistakeLimitReached: \(isMistakeLimitReached)")
        
        if !isComplete && !isGenerating && !isMistakeLimitReached {
            isPaused = false
            
            // Cancel any pending debounced saves to ensure resume state is saved immediately
            saveDebounceTimer?.invalidate()
            saveDebounceTimer = nil
            
            logger.info(self, "Game resumed - saving state (isPaused: \(isPaused))")
            startTimer()
            saveGame() // Save when resuming
        } else {
            logger.info(self, "resumeTimer() did not start timer - conditions not met")
        }
    }
    
    /// Toggles between paused and running states.
    func togglePause() {
        if isPaused {
            resumeTimer()
        } else {
            pauseTimer()
        }
    }
    
    // MARK: - Save/Load Game
    
    /// Loads game state from a Game model into the current game instance.
    ///
    /// This helper consolidates all the logic for restoring a saved game,
    /// including board state, UI state, and undo/redo stacks.
    ///
    /// - Parameters:
    ///   - game: The saved game to load.
    ///   - resetCompletionState: Whether to reset completion flags (for resuming in-progress games).
    func loadGame(from game: Game, clearUIState: Bool = false) {
        logger.info(self, "loadGame() called - gameID: \(game.gameID), isCompleted: \(game.isCompleted), wasPaused: \(game.wasPaused)")
        
        let wasPreviouslyPaused = isPaused

        // Load board state
        board = Game.unflatten(game.boardData)
        notes = Game.decodeNotes(game.notesData)
        solution = Game.unflatten(game.solutionData)
        initialBoard = Game.unflatten(game.initialBoardData)
        hints = Game.unflatten(game.hintsData)
        
        // Set difficulty
        if let difficulty = Difficulty(rawValue: game.difficulty) {
            currentDifficulty = difficulty
        }
        
        // Restore game state
        currentGameID = game.gameID
        elapsedTime = game.elapsedTime
        gameStartDate = game.startDate
        mistakes = game.mistakes
        isDailyChallenge = game.isDailyChallenge
        dailyChallengeDate = game.dailyChallengeDate
        isComplete = game.isCompleted
        
        showConfetti = false
        if game.isCompleted {
            // Reset confetti briefly to trigger animation for each completed game
            // Use a tiny delay to ensure the change is detected
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.showConfetti = true
            }
        }
        
        hasInProgressGame = !isComplete
        isMistakeLimitReached = settings.mistakeLimit > 0 && game.mistakes >= settings.mistakeLimit
        hasError = isComplete && checkErrors()

        // Restore UI state
        if let row = game.selectedCellRow, let col = game.selectedCellCol {
            selectedCell = (row, col)
        } else {
            selectedCell = nil
        }
        highlightedNumber = game.highlightedNumber
        isPencilMode = game.isPencilMode
        isPaused = game.wasPaused
        
        // Restore undo/redo stacks
        undoStack = Game.decodeGameStateStack(game.undoStackData)
        redoStack = Game.decodeGameStateStack(game.redoStackData)


        // Clear UI state
        if clearUIState {
            selectedCell = nil
            highlightedNumber = nil
            isPencilMode = false
        }

        currentGameID = isComplete ? nil : game.gameID

        logger.info(self, "loadGame() timer decision - isComplete: \(isComplete), isPaused: \(isPaused), hasBoardBeenGenerated: \(hasBoardBeenGenerated)")
        
        // Manage timer based on complete and pause states
        if isComplete {
            stopTimer()
            logger.info(self, "Completed game, ensure timer stopped")
        } else if isPaused {
            stopTimer()
            logger.info(self, "Loaded game is paused, timer stopped")
        } else {
            logger.info(self, "Attempting to start timer from loadGame")
            startTimer()
        }

        if wasPreviouslyPaused != isPaused {
            logger.info(self, "Pause state changed: \(wasPreviouslyPaused) -> \(isPaused)")
        }
    }

    /// Saves UI state changes (selectedCell, highlightedNumber, isPencilMode).
    ///
    /// This is a lighter-weight save that uses debouncing to avoid excessive saves
    /// when the user is rapidly changing UI state (e.g., selecting cells).
    func saveUIState() {
        debouncedSave()
    }
    
    /// Debounced save - waits for user to stop making moves before saving.
    ///
    /// Saves the game 3 seconds after the last user action. This prevents excessive
    /// CloudKit operations while ensuring progress is saved at natural break points.
    private func debouncedSave() {
        saveDebounceTimer?.invalidate()
        saveDebounceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.saveGame()
        }
    }
    
    func saveGame() {
        // Don't save if the game is already complete or game over
        if isComplete || isMistakeLimitReached {
            return
        }
        
        // Don't save if the board is empty (not generated yet)
        // This prevents saving invalid game states that confuse the user
        let hasAnyValues = board.flatMap { $0 }.contains { $0 != 0 }
        if !hasAnyValues {
            logger.info(self, "Prevented saving empty/ungenerated board")
            return
        }
        
        currentGameID = persistenceService?.saveInProgressGame(
            gameID: currentGameID,
            board: board,
            notes: notes,
            solution: solution,
            initialBoard: initialBoard,
            difficulty: currentDifficulty.rawValue,
            elapsedTime: elapsedTime,
            startDate: gameStartDate,
            mistakes: mistakes,
            hints: hints,
            isDailyChallenge: isDailyChallenge,
            dailyChallengeDate: dailyChallengeDate,
            selectedCell: selectedCell,
            highlightedNumber: highlightedNumber,
            isPencilMode: isPencilMode,
            isPaused: isPaused,
            undoStack: undoStack,
            redoStack: redoStack
        )
        hasInProgressGame = true
        logger.debug(self, "Game saved (isPaused: \(isPaused), time: \(Int(elapsedTime))s)")
    }

    private func checkForSavedGame() {
        if let savedGame = persistenceService?.fetchInProgressGame() {
            loadGame(from: savedGame)
            hasInProgressGame = true
        } else {
            hasInProgressGame = false
        }
    }
    
    // MARK: - Statistics
    
    private func saveStats() {
        guard let statsModel = statsModel else { return }
        StatsAdapter.updateModel(statsModel, from: stats)
        persistenceService?.saveStatistics(statsModel)
    }
    
    func resetStats() {
        stats = GameStats()
        saveStats()
    }
    
    // MARK: - Undo/Redo
    private func saveState() {
        let state = GameState(board: board, notes: notes)
        undoStack.append(state)
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }
    
    func undo() {
        guard !undoStack.isEmpty else { return }
        let currentState = GameState(board: board, notes: notes)
        redoStack.append(currentState)
        
        let previousState = undoStack.removeLast()
        board = previousState.board
        notes = previousState.notes
        checkCompletion()
        
        // Save after undo (with debounce)
        debouncedSave()
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        let currentState = GameState(board: board, notes: notes)
        undoStack.append(currentState)
        
        let nextState = redoStack.removeLast()
        board = nextState.board
        notes = nextState.notes
        checkCompletion()
        
        // Save after redo (with debounce)
        debouncedSave()
    }
    
    // MARK: - Puzzle Generation
    /// Generates a new Sudoku puzzle with the specified difficulty.
    ///
    /// Creates a complete solution, then removes numbers to create the puzzle.
    /// Generation happens asynchronously on a background thread.
    ///
    /// - Parameters:
    ///   - difficulty: The difficulty level, which determines how many cells to remove.
    ///   - seed: An optional seed for deterministic puzzle generation (used for daily challenges).
    ///   - isDailyChallenge: Whether this puzzle is a daily challenge.
    func generatePuzzle(difficulty: Difficulty, seed: Int? = nil, isDailyChallenge: Bool = false) {
        stopTimer()
        isGenerating = true
        currentDifficulty = difficulty
        self.isDailyChallenge = isDailyChallenge
        
        logger.info(self, "Starting puzzle generation: \(difficulty.name) - Target: \(difficulty.cellsToRemove) cells to remove, \(difficulty.numberOfClues) clues")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if let seed = seed {
                var generator = SeededRandomNumberGenerator(seed: seed)
                var newSolution = Array(repeating: Array(repeating: 0, count: SudokuGame.size), count: SudokuGame.size)
                self.fillBoard(&newSolution, using: &generator)
                let newBoard = self.removeNumbersWithUniqueness(from: newSolution, count: difficulty.cellsToRemove, using: &generator)
                
                DispatchQueue.main.async {
                    self.finalizePuzzleGeneration(solution: newSolution, board: newBoard, difficulty: difficulty)
                }
            } else {
                var newSolution = Array(repeating: Array(repeating: 0, count: SudokuGame.size), count: SudokuGame.size)
                self.fillBoard(&newSolution)
                let newBoard = self.removeNumbersWithUniqueness(from: newSolution, count: difficulty.cellsToRemove)
                
                DispatchQueue.main.async {
                    self.finalizePuzzleGeneration(solution: newSolution, board: newBoard, difficulty: difficulty)
                }
            }
        }
    }
    
    /// Finalizes puzzle generation by updating all game state.
    ///
    /// Resets the game state, statistics, and starts the timer.
    ///
    /// - Parameters:
    ///   - solution: The complete solution grid.
    ///   - board: The puzzle grid with cells removed.
    ///   - difficulty: The difficulty level of the puzzle.
    private func finalizePuzzleGeneration(solution: [[Int]], board: [[Int]], difficulty: Difficulty) {
        // Count actual clues in the generated board
        var actualClues = 0
        for row in board {
            for cell in row {
                if cell != 0 {
                    actualClues += 1
                }
            }
        }
        
        logger.info(self, "Puzzle finalized: \(difficulty.name) - Expected: \(difficulty.numberOfClues) clues, Actual: \(actualClues) clues")
        
        self.solution = solution
        self.board = board
        self.notes = Array(repeating: Array(repeating: Set<Int>(), count: SudokuGame.size), count: SudokuGame.size)
        self.initialBoard = board
        self.isComplete = false
        self.hasError = false
        self.isGenerating = false
        self.isMistakeLimitReached = false
        self.selectedCell = nil
        self.undoStack.removeAll()
        self.redoStack.removeAll()
        self.highlightedNumber = nil
        self.elapsedTime = 0
        self.gameStartDate = Date()
        self.isPaused = false
        self.mistakes = 0
        self.hints = Array(repeating: Array(repeating: 0, count: SudokuGame.size), count: SudokuGame.size)
        self.showConfetti = false
        
        // Clear game ID for new game (will be generated on first save)
        self.currentGameID = nil
        
        self.stats.recordStart(difficulty: difficulty.rawValue)
        self.saveStats()
        self.saveGame()
        
        logger.info(self, "Attempting to start timer from finalizePuzzleGeneration - hasBoardBeenGenerated: \(hasBoardBeenGenerated)")
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
        for row in 0..<SudokuGame.size {
            for col in 0..<SudokuGame.size {
                if grid[row][col] == 0 {
                    let nums = (1...SudokuGame.size).shuffled(using: &generator)
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
        for row in 0..<SudokuGame.size {
            for col in 0..<SudokuGame.size {
                if grid[row][col] == 0 {
                    let nums = (1...SudokuGame.size).shuffled()
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
        var removed = 0
        var passCount = 0
        let maxPasses = 5
        
        logger.debug(self, "Starting multi-pass removal (target: \(count) cells)")
        
        while removed < count && passCount < maxPasses {
            passCount += 1
            var positions = [(Int, Int)]()
            
            // Collect all non-zero positions
            for r in 0..<SudokuGame.size {
                for c in 0..<SudokuGame.size {
                    if puzzle[r][c] != 0 {
                        positions.append((r, c))
                    }
                }
            }
            
            positions.shuffle(using: &generator)
            var removedThisPass = 0
            
            for (r, c) in positions {
                if removed >= count { break }
                
                let backup = puzzle[r][c]
                puzzle[r][c] = 0
                
                if hasUniqueSolution(puzzle) {
                    removed += 1
                    removedThisPass += 1
                } else {
                    puzzle[r][c] = backup
                }
            }
            
            logger.debug(self, "Pass \(passCount): Removed \(removedThisPass) cells (total: \(removed)/\(count))")
            
            // If we made no progress, break early
            if removedThisPass == 0 {
                logger.debug(self, "No progress made, stopping early")
                break
            }
        }
        
        let cluesRemaining = Self.numberOfCells - removed
        logger.info(self, "Puzzle Generation (Seeded): Removed \(removed)/\(count) cells, \(cluesRemaining) clues remaining")
        
        return puzzle
    }
    
    private func removeNumbersWithUniqueness(from solution: [[Int]], count: Int) -> [[Int]] {
        var puzzle = solution
        var removed = 0
        var passCount = 0
        let maxPasses = 5
        
        logger.debug(self, "Starting multi-pass removal (target: \(count) cells)")
        
        while removed < count && passCount < maxPasses {
            passCount += 1
            var positions = [(Int, Int)]()
            
            // Collect all non-zero positions
            for r in 0..<SudokuGame.size {
                for c in 0..<SudokuGame.size {
                    if puzzle[r][c] != 0 {
                        positions.append((r, c))
                    }
                }
            }
            
            positions.shuffle()
            var removedThisPass = 0
            
            for (r, c) in positions {
                if removed >= count { break }
                
                let backup = puzzle[r][c]
                puzzle[r][c] = 0
                
                if hasUniqueSolution(puzzle) {
                    removed += 1
                    removedThisPass += 1
                } else {
                    puzzle[r][c] = backup
                }
            }
            
            logger.debug(self, "Pass \(passCount): Removed \(removedThisPass) cells (total: \(removed)/\(count))")
            
            // If we made no progress, break early
            if removedThisPass == 0 {
                logger.debug(self, "No progress made, stopping early")
                break
            }
        }
        
        let cluesRemaining = Self.numberOfCells - removed
        logger.info(self, "Puzzle Generation: Removed \(removed)/\(count) cells, \(cluesRemaining) clues remaining")
        
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
        
        outer: for r in 0..<SudokuGame.size {
            for c in 0..<SudokuGame.size {
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
        
        for num in 1...SudokuGame.size {
            if isValid(grid, emptyRow, emptyCol, num) {
                grid[emptyRow][emptyCol] = num
                countSolutions(&grid, &count, maxCount: maxCount)
                grid[emptyRow][emptyCol] = 0
                
                if count >= maxCount { return }
            }
        }
    }
    
    func isValid(_ grid: [[Int]], _ row: Int, _ col: Int, _ num: Int) -> Bool {
        for c in 0..<SudokuGame.size {
            if grid[row][c] == num { return false }
        }
        
        for r in 0..<SudokuGame.size {
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
    
    /// Sets a number in the currently selected cell.
    ///
    /// In pencil mode, toggles the number as a note. Otherwise, places the number
    /// and checks for errors if auto error checking is enabled.
    ///
    /// - Parameter num: The number (1-9) to set.
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
                
                // Remove this number from notes in related cells
                removeNumberFromRelatedNotes(row: cell.row, col: cell.col, num: num)
                
                if settings.autoErrorChecking && num != solution[cell.row][cell.col] {
                    mistakes += 1
                    if settings.hapticFeedback {
                        triggerErrorHaptic.toggle()
                    }
                    
                    if settings.mistakeLimit > 0 && mistakes >= settings.mistakeLimit {
                        isMistakeLimitReached = true
                        stopTimer()
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.lastPlacedCell = nil
                }
                
                checkCompletion()
            }
            
            // Save after user action (with debounce)
            debouncedSave()
        }
    }
    
    /// Clears the value and notes from the currently selected cell.
    func clearCell() {
        guard let cell = selectedCell else { return }
        if initialBoard[cell.row][cell.col] == 0 {
            saveState()
            board[cell.row][cell.col] = 0
            notes[cell.row][cell.col].removeAll()
            hasError = false
            isComplete = false
            
            // Save after user action (with debounce)
            debouncedSave()
        }
    }
    
    /// Automatically fills all empty cells with possible candidate notes.
    ///
    /// For each empty cell, adds notes for all numbers that don't violate
    /// Sudoku rules in the cell's row, column, and 3x3 box.
    func autoFillNotes() {
        saveState()
        for r in 0..<SudokuGame.size {
            for c in 0..<SudokuGame.size {
                if board[r][c] == 0 && initialBoard[r][c] == 0 {
                    notes[r][c].removeAll()
                    for num in 1...SudokuGame.size {
                        if isValid(board, r, c, num) {
                            notes[r][c].insert(num)
                            hints[r][c] = 1
                        }
                    }
                }
            }
        }
        
        // Save after auto-filling notes (with debounce)
        debouncedSave()
    }
    
    /// Removes a number from notes in all cells related to the given position.
    ///
    /// When a number is placed in a cell, this function removes that number
    /// from the notes of all cells in the same row, column, and 3x3 box.
    ///
    /// - Parameters:
    ///   - row: The row of the cell where the number was placed.
    ///   - col: The column of the cell where the number was placed.
    ///   - num: The number that was placed.
    private func removeNumberFromRelatedNotes(row: Int, col: Int, num: Int) {
        // Remove from same row
        for c in 0..<SudokuGame.size {
            notes[row][c].remove(num)
        }
        
        // Remove from same column
        for r in 0..<SudokuGame.size {
            notes[r][col].remove(num)
        }
        
        // Remove from same 3x3 box
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<boxRow + 3 {
            for c in boxCol..<boxCol + 3 {
                notes[r][c].remove(num)
            }
        }
    }
    
    /// Clears all notes from all cells in the puzzle.
    func clearAllNotes() {
        saveState()
        for r in 0..<SudokuGame.size {
            for c in 0..<SudokuGame.size {
                notes[r][c].removeAll()
            }
        }
        
        // Save after clearing notes (with debounce)
        debouncedSave()
    }

    /// Returns `true` if the board has errors
    func checkErrors() -> Bool {
        for r in 0..<SudokuGame.size {
            for c in 0..<SudokuGame.size {
                if board[r][c] != solution[r][c] {
                    return true
                }
            }
        }
        return false
    }

    /// Checks if the puzzle has been completed successfully.
    func checkCompletion() {
        for row in board {
            if row.contains(0) {
                isComplete = false
                return
            }
        }
        
        hasError = checkErrors()
        if hasError {
            return
        }

        isComplete = true
        showConfetti = true
        stopTimer()
        
        // Save the completed game to history with full hints grid
        if let gameID = currentGameID {
            persistenceService?.saveCompletedGame(
                gameID: gameID,
                initialBoard: initialBoard,
                solution: solution,
                finalBoard: board,
                difficulty: currentDifficulty.rawValue,
                completionTime: elapsedTime,
                startDate: gameStartDate,
                completionDate: Date(),
                mistakes: mistakes,
                hints: hints,
                isDailyChallenge: isDailyChallenge,
                dailyChallengeDate: dailyChallengeDate
            )
        }
        
        stats.recordWin(difficulty: currentDifficulty.rawValue, time: elapsedTime)
        saveStats()
        
        hasInProgressGame = false // No longer have an in-progress game to resume
        
        if settings.hapticFeedback {
            triggerSuccessHaptic.toggle()
        }
        
        if isDailyChallenge {
            // Mark this difficulty's daily challenge as completed
            settings.markDailyChallengeCompleted(for: currentDifficulty)
            saveSettings()
            
            // Record daily challenge stats
            let today = DailyChallenge.getDateString(for: Date())
            let allCompleted = settings.areAllDailyChallengesCompleted()
            stats.dailyChallengeStats.recordDailyWin(
                difficulty: currentDifficulty.rawValue,
                time: elapsedTime,
                date: today,
                allCompleted: allCompleted
            )
            saveStats()
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
        // Find the best cell to fill next - one without notes and with the fewest possible candidates
        var bestCell: (row: Int, col: Int)? = nil
        var fewestCandidates = 10
        
        for r in 0..<SudokuGame.size {
            for c in 0..<SudokuGame.size {
                // Only consider empty cells without any notes
                if board[r][c] == 0 && notes[r][c].isEmpty {
                    let candidates = getPossibleNumbers(row: r, col: c)
                    if candidates.count > 0 && candidates.count < fewestCandidates {
                        fewestCandidates = candidates.count
                        bestCell = (r, c)
                    }
                }
            }
        }
        
        // Fill in the notes for the best cell
        if let cell = bestCell {
            let candidates = getPossibleNumbers(row: cell.row, col: cell.col)
            saveState()
            notes[cell.row][cell.col] = candidates
            selectedCell = cell
            hints[cell.row][cell.col] = 1
            
            // Save after giving hint (with debounce)
            debouncedSave()
        }
    }
    
    func hasHint(row: Int, col: Int) -> Bool {
        return hints[row][col] == 1
    }
    
    // Helper function to get possible numbers for a cell
    private func getPossibleNumbers(row: Int, col: Int) -> Set<Int> {
        var possible = Set(1...SudokuGame.size)
        
        // Remove numbers in the same row
        for c in 0..<SudokuGame.size {
            if board[row][c] != 0 {
                possible.remove(board[row][c])
            }
        }
        
        // Remove numbers in the same column
        for r in 0..<SudokuGame.size {
            if board[r][col] != 0 {
                possible.remove(board[r][col])
            }
        }
        
        // Remove numbers in the same 3x3 box
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<boxRow + 3 {
            for c in boxCol..<boxCol + 3 {
                if board[r][c] != 0 {
                    possible.remove(board[r][c])
                }
            }
        }
        
        return possible
    }
    
    // MARK: - Daily Challenge
    func generateDailyChallenge(difficulty: Difficulty) {
        let today = Date()
        let seed = DailyChallenge.getSeed(for: today)
        let dateString = DailyChallenge.getDateString(for: today)
        
        // Check if a daily challenge for this difficulty and date already exists
        if let existingChallenge = persistenceService?.fetchDailyChallenge(
            difficulty: difficulty.rawValue,
            dateString: dateString
        ) {
            logger.info(self, "Loading existing daily challenge: \(difficulty.name) for \(dateString)")
            loadGame(from: existingChallenge)
            return
        }
        
        // No existing challenge found - generate a new one
        logger.info(self, "Generating new daily challenge: \(difficulty.name) for \(dateString)")
        generatePuzzle(difficulty: difficulty, seed: seed, isDailyChallenge: true)
        dailyChallengeDate = dateString
    }
    
    /// Checks if a specific difficulty's daily challenge has been completed today.
    ///
    /// - Parameter difficulty: The difficulty level to check.
    /// - Returns: `true` if today's daily challenge for this difficulty has been completed.
    func isDailyChallengeCompleted(for difficulty: Difficulty) -> Bool {
        return settings.isDailyChallengeCompleted(for: difficulty)
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
        guard code.count == Self.numberOfCells else { return false }
        
        var newBoard = Array(repeating: Array(repeating: 0, count: SudokuGame.size), count: SudokuGame.size)
        var index = 0
        
        for r in 0..<SudokuGame.size {
            for c in 0..<SudokuGame.size {
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
        notes = Array(repeating: Array(repeating: Set<Int>(), count: SudokuGame.size), count: SudokuGame.size)
        mistakes = 0
        hints = Array(repeating: Array(repeating: 0, count: SudokuGame.size), count: SudokuGame.size)
        elapsedTime = 0
        isComplete = false
        isMistakeLimitReached = false
        isDailyChallenge = false
        
        logger.info(self, "Attempting to start timer from loadFromCode - hasBoardBeenGenerated: \(hasBoardBeenGenerated)")
        startTimer()
        return true
    }
    
    private func solvePuzzle(_ grid: inout [[Int]]) -> Bool {
        for row in 0..<SudokuGame.size {
            for col in 0..<SudokuGame.size {
                if grid[row][col] == 0 {
                    for num in 1...SudokuGame.size {
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
        for r in 0..<SudokuGame.size {
            for c in 0..<SudokuGame.size {
                if board[r][c] == num {
                    count += 1
                }
            }
        }
        return count
    }
}
