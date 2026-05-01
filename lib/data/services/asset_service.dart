// import '../../core/network/dio_client.dart';
// import '../../core/network/api_response.dart';
// import '../../core/constants/api_endpoints.dart';
// import '../repositories/asset_repository.dart';
//
// // class AssetService implements AssetRepository {
//   final DioClient _dioClient;
//   AssetService({required DioClient dioClient}) : _dioClient = dioClient;
//
//   @override
//   Future<PaginatedResponse<Map<String, dynamic>>> getSubmissions({int page = 1}) async {
//     final r = await _dioClient.get(ApiEndpoints.submissionInfo, queryParameters: {'page': page});
//     return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
//   }
//
//   @override
//   Future<Map<String, dynamic>> createSubmission(Map<String, dynamic> data) async {
//     final r = await _dioClient.post(ApiEndpoints.submissionInfo, data: data);
//     return r.data['data'] as Map<String, dynamic>;
//   }
//
//   @override
//   Future<Map<String, dynamic>> updateSubmissionStatus(String id, String status, {String? notes}) async {
//     final r = await _dioClient.put('${ApiEndpoints.submissionInfo}/$id/status', data: {'status': status, if (notes != null) 'notes': notes});
//     return r.data['data'] as Map<String, dynamic>;
//   }
//
//   @override
//   Future<PaginatedResponse<Map<String, dynamic>>> getItemLoans({int page = 1, String? status}) async {
//     final r = await _dioClient.get(ApiEndpoints.itemLoan, queryParameters: {'page': page, if (status != null) 'status': status});
//     return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
//   }
//
//   @override
//   Future<Map<String, dynamic>> requestLoan(Map<String, dynamic> data) async {
//     final r = await _dioClient.post(ApiEndpoints.itemLoan, data: data);
//     return r.data['data'] as Map<String, dynamic>;
//   }
//
//   @override
//   Future<Map<String, dynamic>> returnLoan(String id) async {
//     final r = await _dioClient.put('${ApiEndpoints.itemLoan}/$id/return');
//     return r.data['data'] as Map<String, dynamic>;
//   }
//
//   @override
//   Future<PaginatedResponse<Map<String, dynamic>>> getEquipmentSubmissions({int page = 1}) async {
//     final r = await _dioClient.get(ApiEndpoints.equipmentSubmission, queryParameters: {'page': page});
//     return PaginatedResponse.fromJson(r.data, (j) => j as Map<String, dynamic>);
//   }
//
//   @override
//   Future<Map<String, dynamic>> submitEquipment(Map<String, dynamic> data) async {
//     final r = await _dioClient.post(ApiEndpoints.equipmentSubmission, data: data);
//     return r.data['data'] as Map<String, dynamic>;
//   }
//
//   @override
//   Future<Map<String, dynamic>> submitLoanResponse(String loanId, Map<String, dynamic> data) async {
//     final r = await _dioClient.post('${ApiEndpoints.loanResponse}/$loanId', data: data);
//     return r.data['data'] as Map<String, dynamic>;
//   }
//
//   @override
//   Future<Map<String, dynamic>> submitTreasurerResponse(String submissionId, Map<String, dynamic> data) async {
//     final r = await _dioClient.post('${ApiEndpoints.treasurerResponse}/$submissionId', data: data);
//     return r.data['data'] as Map<String, dynamic>;
//   }
//
//   @override
//   Future<Map<String, dynamic>> submitPrincipalResponse(String submissionId, Map<String, dynamic> data) async {
//     final r = await _dioClient.post('${ApiEndpoints.principalResponse}/$submissionId', data: data);
//     return r.data['data'] as Map<String, dynamic>;
//   }
// }
