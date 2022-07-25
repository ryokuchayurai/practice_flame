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

  double attackPower = 10;
  double knockBack = 20;

  int attackInterval = 500;

  double attackRange = 1;
}

class HeroineInfo {
  int hp = 10;
  int level = 1;
  int point = 0;

  int magicArrow = 1;
  int magicCircle = 0;
  int magicLock = 0;
  int magicLaser = 0;

  int castTime = 2000;
  int castInterval = 1000;

  double castRange = 300;
}

final gameInfo = GameInfo();
