class GameInfo {
  PlayerInfo playerInfo = PlayerInfo();
  HeroineInfo heroineInfo = HeroineInfo();
  SkillInfo skillInfo = SkillInfo();

  reset() {
    playerInfo = PlayerInfo();
    heroineInfo = HeroineInfo();
    skillInfo = SkillInfo();
  }
}

class SkillInfo {
  int get run => skills[0];
  int get arm => skills[1];
  int get range => skills[2];
  int get interval => skills[3];

  int get arrow => skills[4];
  int get ice => skills[5];
  int get fire => skills[6];
  int get thunder => skills[7];

  List<int> skills = [0, 0, 0, 0, 1, 0, 0, 0];
}

class PlayerInfo {
  int hp = 10;
  int point = 0;

  double speed = 60;

  double attackPower = 10;
  double knockBack = 30;

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
