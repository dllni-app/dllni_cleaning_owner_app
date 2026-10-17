class SupervisedWorkerBooking {
  const SupervisedWorkerBooking({
    required this.id,
    required this.bookingNumber,
    required this.status,
    required this.tasks,
    required this.specializedServices,
    required this.allowedActions,
    this.scheduledDate,
    this.scheduledTime,
    this.neighborhoodName,
    this.supervisorName,
    this.propertyType,
    this.propertyDetails = const {},
  });

  final int id;
  final String bookingNumber;
  final String status;
  final String? scheduledDate;
  final String? scheduledTime;
  final String? neighborhoodName;
  final String? supervisorName;
  final String? propertyType;
  final Map<String, dynamic> propertyDetails;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> specializedServices;
  final List<String> allowedActions;

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.map((k, v) => MapEntry(k.toString(), v)) : {};
  static List<Map<String, dynamic>> _list(dynamic value) =>
      value is List ? value.map(_map).toList(growable: false) : [];

  factory SupervisedWorkerBooking.fromJson(dynamic response) {
    final data = _map(_map(response)['data']);
    if (data['serviceType'] != 'supervised_team') {
      throw const FormatException('Unexpected supervised booking response');
    }
    return SupervisedWorkerBooking(
      id: (data['id'] as num).toInt(),
      bookingNumber: data['bookingNumber']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      scheduledDate: data['scheduledDate']?.toString(),
      scheduledTime: data['scheduledTime']?.toString(),
      neighborhoodName: data['neighborhoodName']?.toString(),
      supervisorName: _map(data['supervisor'])['name']?.toString(),
      propertyType: data['propertyType']?.toString(),
      propertyDetails: _map(data['propertyDetails']),
      tasks: _list(data['tasks']),
      specializedServices: _list(data['specializedServices']),
      allowedActions: data['allowedActions'] is List
          ? (data['allowedActions'] as List).map((a) => a.toString()).toList()
          : const [],
    );
  }
}
