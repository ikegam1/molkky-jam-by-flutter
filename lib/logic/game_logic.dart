import '../models/game_models.dart';

class GameLogic {
  static void processThrow(Player player, List<int> knockedDownSkitels, MolkkyMatch match) {
    if (player.isDisqualified) return;

    int points = 0;
    if (knockedDownSkitels.isEmpty) {
      points = 0;
      player.consecutiveMisses++;
      if (player.consecutiveMisses >= match.maxMisses) {
        player.isDisqualified = true;
      }
    } else {
      player.consecutiveMisses = 0;

      if (knockedDownSkitels.length == 1) {
        points = knockedDownSkitels.first;
      } else {
        points = knockedDownSkitels.length;
      }

      int nextScore = player.currentScore + points;
      if (nextScore > match.targetScore) {
        player.currentScore = match.burstResetScore;
      } else {
        player.currentScore = nextScore;
      }
    }

    player.scoreHistory.add(points);
  }

  static bool checkSetWinner(Player player, MolkkyMatch match) {
    if (player.currentScore == match.targetScore) {
      player.setsWon++;
      return true;
    }
    return false;
  }
}
