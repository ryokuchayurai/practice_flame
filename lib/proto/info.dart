class GameInfo {
  PlayerInfo playerInfo = PlayerInfo();
}

class PlayerInfo {
  int hp = 10;
  int point = 0;

  double speed = 60;
  double knockBack = 20;
  int attackInterval = 500;
  double atackRange = 1;
}

final gameInfo = GameInfo();
