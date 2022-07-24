class GameInfo {
  PlayerInfo playerInfo = PlayerInfo();
  HeroineInfo heroineInfo = HeroineInfo();

  reset() {
    playerInfo = PlayerInfo();
    heroineInfo = HeroineInfo();
  }
}

class PlayerInfo {
  int hp = 10;
  int point = 0;

  double speed = 60;
  double knockBack = 20;
  int attackInterval = 500;
  double atackRange = 1;
}

class HeroineInfo {
  int hp = 10;
  int level = 1;
  int point = 0;

  int castTime = 2000;
  int castInterval = 1000;
}

final gameInfo = GameInfo();
