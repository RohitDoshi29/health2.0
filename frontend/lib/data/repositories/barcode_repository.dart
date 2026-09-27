import '../../core/config/api_constants.dart';
import '../models/barcode_model.dart';
import '../services/api_client.dart';

class BarcodeRepository {
  final ApiClient _apiClient;

  BarcodeRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<BarcodeProductModel?> lookupBarcode(String barcode) async {
    final cleanCode = barcode.trim();
    if (cleanCode.isEmpty) {
      return null;
    }

    try {
      final response = await _apiClient.get('${ApiConstants.barcode}/$cleanCode');
      if (response != null && response is Map<String, dynamic>) {
        return BarcodeProductModel.fromJson(response);
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}

