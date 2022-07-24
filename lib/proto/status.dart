class GameStatus {
  GameMode mode = GameMode.main;
}

enum GameMode {
  main,
  levelUp,
  gameOver,
}

final gameStatus = GameStatus();
