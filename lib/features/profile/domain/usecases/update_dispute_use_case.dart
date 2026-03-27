import 'package:injectable/injectable.dart';
import 'package:common_package/helpers/typedef.dart';
import '../repository/profile_repo.dart';
import '../../data/models/update_dispute_model.dart';

@lazySingleton
class UpdateDisputeUseCase implements UseCase<UpdateDisputeModel, UpdateDisputeParams> {
  final ProfileRepo profile;

  UpdateDisputeUseCase({required this.profile});

  @override
  DataResponse<UpdateDisputeModel> call(UpdateDisputeParams params) {
    return profile.updateDispute(params);
  }
}

class UpdateDisputeParams with Params {
  final int disputeId;
  final int bookingId;
  final String bookingType;
  final String ticketNumber;
  final String category;
  final String status;
  final String resolution;

  UpdateDisputeParams({
    required this.disputeId,
    required this.bookingId,
    required this.bookingType,
    required this.ticketNumber,
    required this.category,
    required this.status,
    required this.resolution,
  });

  @override
  Map<String, dynamic> getBody() => {
        "bookingId": bookingId,
        "bookingType": bookingType,
        "ticketNumber": ticketNumber,
        "category": category,
        "status": status,
        "resolution": resolution,
      };
}
