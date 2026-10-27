import '../../contracts/models.dart';

/// A scheduled, not-yet-started mission can offer SOS from one hour before
/// the authoritative appointment instant. A worker already on an active
/// mission must not lose access to emergency assistance just because the
/// backend omitted the schedule field in an old payload.
class MissionSosWindowPolicy {
  const MissionSosWindowPolicy._();

  static bool permits(MissionView view, {DateTime? now}) {
    if (const {
          'cancelled',
          'completed',
          'rejected',
          'unassigned',
        }.contains(view.status) ||
        const {
          'cancelled',
          'completed',
          'rejected',
          'unassigned',
        }.contains(view.ownAssignmentStatus)) {
      return false;
    }

    if (view.startedAt != null ||
        view.billableStartAt != null ||
        view.status == 'in_progress' ||
        view.ownAssignmentStatus == 'in_progress') {
      return true;
    }

    final startsAt = view.scheduledStartsAt;
    if (startsAt == null) return false;
    return !(now ?? DateTime.now()).toUtc().isBefore(
      startsAt.toUtc().subtract(const Duration(hours: 1)),
    );
  }
}
