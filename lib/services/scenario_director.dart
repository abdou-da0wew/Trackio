import 'dart:async';
import 'simulation_engine.dart';

/// Runs the scripted "movie mode" for the offline simulation source.
///
/// One tap plays the entire loss-recovery story with captions. Every phase
/// maps to real engine state transitions so the UI, alerts and history all
/// react exactly as they would in production.
///
/// Captions are NOT stored here — the engine only carries the machine
/// readable [SimulationEngine.scenarioPhase]; the UI resolves the localized
/// caption text (see `core/l10n_text.dart`).
class ScenarioDirector {
  ScenarioDirector(this._engine);

  final SimulationEngine _engine;
  final List<Timer> _timers = [];
  int _step = 0;

  bool get running => _engine.scenarioRunning;

  void start() {
    stop();
    _engine.resetSession();
    _engine.scenarioRunning = true;
    _engine.scenarioPhase = 'intro';
    _engine.setSpeed(4); // brisk story pacing, still readable
    _engine.start();
    _engine.notifyUI();

    _after(14, () => _phase('leftBehind', () {
          _engine.driftAway();
        }));

    // warning triggers naturally at 30 m; lost triggers at 80 m → engine fires
    // the alert, plays the alarm and auto-enters panic mode (1600 ms).

    _whenPhase('panic', () => _phase('panic', () {
          _every(2, (_) => _engine.sendPanicPacket());
          _after(9, () => _phase('recovering', () {
                _engine.beginRecovery();
              }));
        }));

    // when distance ≤ 25 m the engine logs 'reconnected'; near ≤ 9 m the UI
    // prompts the user (auto-confirm after a beat in movie mode).
    _whenPhase('near', () {
      _after(5, () => _phase('found', () {
            _engine.markFound();
            _engine.setSpeed(1);
          }));
    });
  }

  void _phase(String name, void Function() action) {
    _engine.scenarioPhase = name;
    action();
    _engine.notifyUI();
  }

  void _whenPhase(String phase, void Function() run) {
    _step++;
    final id = _step;
    late final Timer t;
    t = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!running || _engine.scenarioPhase == null) {
        timer.cancel();
        return;
      }
      if (_engine.scenarioPhase == phase) {
        timer.cancel();
        _timers.remove(t);
        // run only for this director instance's step
        if (id == _step) run();
      }
    });
    _timers.add(t);
  }

  void _after(int seconds, void Function() run) {
    _timers.add(Timer(Duration(seconds: seconds), run));
  }

  void _every(int seconds, void Function(int) run) {
    var i = 0;
    _timers.add(Timer.periodic(Duration(seconds: seconds), (t) {
      if (!running) {
        t.cancel();
        return;
      }
      run(++i);
    }));
  }

  void stop() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _engine.scenarioRunning = false;
  }
}
