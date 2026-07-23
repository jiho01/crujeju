import '../models/models.dart';
import 'app_data.dart';

class GuideItineraryStop {
  const GuideItineraryStop({
    required this.time,
    required this.title,
    required this.detail,
    this.fromTravelerSelection = false,
  });

  final String time;
  final String title;
  final String detail;
  final bool fromTravelerSelection;
}

List<Place> selectedGuidePlaces(Set<String> savedPlaceIds) {
  return AppData.places
      .where((place) => savedPlaceIds.contains(place.id))
      .toList(growable: false);
}

List<GuideItineraryStop> buildGuideItinerary({
  required GuideBooking booking,
  required Guide guide,
  required CruiseOption cruise,
  required List<Place> selectedPlaces,
}) {
  final firstPlace = selectedPlaces.isEmpty
      ? AppData.places.first
      : selectedPlaces.first;
  final secondPlace = selectedPlaces.length > 1
      ? selectedPlaces[1]
      : AppData.places[1];
  return [
    GuideItineraryStop(
      time: booking.startTime,
      title: '${cruise.port}에서 미팅',
      detail: '${guide.name} 가이드와 일정 확인',
    ),
    GuideItineraryStop(
      time: _offsetBookingTime(
        booking.startTime,
        booking.durationMinutes * 22 ~/ 100,
      ),
      title: firstPlace.name,
      detail: '${firstPlace.category} · ${firstPlace.stayTime}분',
      fromTravelerSelection: selectedPlaces.contains(firstPlace),
    ),
    GuideItineraryStop(
      time: _offsetBookingTime(
        booking.startTime,
        booking.durationMinutes * 48 ~/ 100,
      ),
      title: '제주 로컬 식당',
      detail: '가이드 추천 점심 · 60분',
    ),
    GuideItineraryStop(
      time: _offsetBookingTime(
        booking.startTime,
        booking.durationMinutes * 70 ~/ 100,
      ),
      title: secondPlace.name,
      detail: '${secondPlace.category} · ${secondPlace.stayTime}분',
      fromTravelerSelection: selectedPlaces.contains(secondPlace),
    ),
    GuideItineraryStop(
      time: booking.endTime,
      title: '${cruise.port} 복귀',
      detail: '출항 ${cruise.departure} · 안전하게 승선',
    ),
  ];
}

String _offsetBookingTime(String time, int offsetMinutes) {
  final parts = time.split(':');
  if (parts.length != 2) return time;
  final base =
      (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  final value = (base + offsetMinutes) % (24 * 60);
  return '${(value ~/ 60).toString().padLeft(2, '0')}:'
      '${(value % 60).toString().padLeft(2, '0')}';
}
