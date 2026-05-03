
UpdateDisputeModel updateDisputeModelFromJson(str) => UpdateDisputeModel.fromJson(str);

class UpdateDisputeModel {
  final String? message;
  final bool? success;

  UpdateDisputeModel({this.message, this.success});

  factory UpdateDisputeModel.fromJson(Map<String, dynamic> json) => UpdateDisputeModel(
        message: json["message"],
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "success": success,
      };
}
