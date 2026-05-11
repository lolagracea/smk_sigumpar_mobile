import '../../core/network/api_response.dart';

abstract class AssetRepository {
  // Submissions
  Future<PaginatedResponse<Map<String, dynamic>>> getSubmissions({int page = 1});
  Future<Map<String, dynamic>> createSubmission(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateSubmissionStatus(String id, String status, {String? notes});

  // Item Loans
  Future<PaginatedResponse<Map<String, dynamic>>> getItemLoans({int page = 1, String? status});
  Future<Map<String, dynamic>> requestLoan(Map<String, dynamic> data);
  Future<Map<String, dynamic>> returnLoan(String id);

  // Equipment Submission
  Future<PaginatedResponse<Map<String, dynamic>>> getEquipmentSubmissions({int page = 1});
  Future<Map<String, dynamic>> submitEquipment(Map<String, dynamic> data);

  // Responses
  Future<Map<String, dynamic>> submitLoanResponse(String loanId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> submitTreasurerResponse(String submissionId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> submitPrincipalResponse(String submissionId, Map<String, dynamic> data);
}
