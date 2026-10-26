import 'base/event_bus_util.dart';

class AvailableCoinsChangeEvent extends BaseEvent {
  final int coins;

  AvailableCoinsChangeEvent({
    required this.coins,
  });
}
