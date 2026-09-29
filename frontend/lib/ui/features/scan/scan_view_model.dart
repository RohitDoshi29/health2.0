import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/analysis_model.dart';
import '../../../data/models/barcode_model.dart';
import '../../../data/models/meal_model.dart';
import '../../../data/models/nutrition_model.dart';
import '../../../data/repositories/analysis_repository.dart';
import '../../../data/repositories/barcode_repository.dart';
import '../../../data/repositories/meal_repository.dart';

enum ScanState { initial, capturing, analyzing, reviewing, saving, success, error }

class ScanViewModel extends ChangeNotifier {
  final AnalysisRepository _analysisRepository;
  final BarcodeRepository _barcodeRepository;
  final MealRepository _mealRepository;
  final ImagePicker _picker;

  ScanState _state = ScanState.initial;
  ScanState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  XFile? _selectedImage;
  XFile? get selectedImage => _selectedImage;

  Uint8List? _imageBytes;
  Uint8List? get imageBytes => _imageBytes;

  MealAnalysisResponseModel? _analysisResult;
  MealAnalysisResponseModel? get analysisResult => _analysisResult;

  BarcodeProductModel? _scannedProduct;
  BarcodeProductModel? get scannedProduct => _scannedProduct;

  bool _isLookingUpBarcode = false;
  bool get isLookingUpBarcode => _isLookingUpBarcode;

  List<MealItemAnalysisModel> _editableItems = [];
  List<MealItemAnalysisModel> get editableItems => _editableItems;

  String _selectedMealType = 'lunch';
  String get selectedMealType => _selectedMealType;

  MealModel? _savedMeal;
  MealModel? get savedMeal => _savedMeal;

  ScanViewModel({
    AnalysisRepository? analysisRepository,
    BarcodeRepository? barcodeRepository,
    MealRepository? mealRepository,
    ImagePicker? picker,
  })  : _analysisRepository = analysisRepository ?? AnalysisRepository(),
        _barcodeRepository = barcodeRepository ?? BarcodeRepository(),
        _mealRepository = mealRepository ?? MealRepository(),
        _picker = picker ?? ImagePicker();

  void setMealType(String mealType) {
    _selectedMealType = mealType;
    notifyListeners();
  }

  void updateItemQuantity(int index, double newQuantity) {
    if (index >= 0 && index < _editableItems.length && newQuantity > 0) {
      final item = _editableItems[index];
      final ratio = item.quantity > 0 ? newQuantity / item.quantity : 1.0;

      item.quantity = newQuantity;
      item.estimatedCalories = (item.estimatedCalories * ratio).roundToDouble();
      item.protein = double.parse((item.protein * ratio).toStringAsFixed(2));
      item.carbohydrates = double.parse((item.carbohydrates * ratio).toStringAsFixed(2));
      item.fat = double.parse((item.fat * ratio).toStringAsFixed(2));
      item.fiber = double.parse((item.fiber * ratio).toStringAsFixed(2));

      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _editableItems.length) {
      _editableItems.removeAt(index);
      notifyListeners();
    }
  }

  double get totalCalories => _editableItems.fold(0.0, (sum, i) => sum + i.estimatedCalories);
  double get totalProtein => _editableItems.fold(0.0, (sum, i) => sum + i.protein);
  double get totalCarbs => _editableItems.fold(0.0, (sum, i) => sum + i.carbohydrates);
  double get totalFat => _editableItems.fold(0.0, (sum, i) => sum + i.fat);
  double get totalFiber => _editableItems.fold(0.0, (sum, i) => sum + i.fiber);

  Future<void> pickAndAnalyze(ImageSource source) async {
    try {
      _state = ScanState.capturing;
      _errorMessage = null;
      notifyListeners();

      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (file == null) {
        _state = ScanState.initial;
        notifyListeners();
        return;
      }

      _selectedImage = file;
      _imageBytes = await file.readAsBytes();

      _state = ScanState.analyzing;
      notifyListeners();

      final result = await _analysisRepository.analyzeFoodImage(
        imageBytes: _imageBytes!,
        filename: file.name.isNotEmpty ? file.name : 'plate.jpg',
      );

      _analysisResult = result;
      _editableItems = List.from(result.items);
      _state = ScanState.reviewing;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _state = ScanState.error;
      notifyListeners();
    }
  }

  void cancelAnalysis() {
    _state = ScanState.initial;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> saveMeal() async {
    if (_editableItems.isEmpty) {
      _errorMessage = 'Please add at least one food item to save.';
      notifyListeners();
      return false;
    }

    try {
      _state = ScanState.saving;
      notifyListeners();

      _savedMeal = await _mealRepository.saveMeal(
        mealType: _selectedMealType,
        items: _editableItems,
        imageUrl: _analysisResult?.imageUrl,
      );

      _state = ScanState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ScanState.error;
      notifyListeners();
      return false;
    }
  }

  Future<BarcodeProductModel?> lookupBarcode(String barcode) async {
    final cleanCode = barcode.trim();
    if (cleanCode.isEmpty) {
      _errorMessage = 'Please enter a valid barcode';
      notifyListeners();
      return null;
    }

    try {
      _isLookingUpBarcode = true;
      _errorMessage = null;
      notifyListeners();

      final product = await _barcodeRepository.lookupBarcode(cleanCode);
      _scannedProduct = product;
      if (product == null) {
        _errorMessage = 'Product with barcode "$cleanCode" was not found in OpenFoodFacts.';
      }
      return product;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLookingUpBarcode = false;
      notifyListeners();
    }
  }

  void addBarcodeProductToPlate(BarcodeProductModel product, {double multiplier = 1.0}) {
    final item = product.toMealItemAnalysis(multiplier: multiplier);
    _editableItems.add(item);

    _analysisResult ??= MealAnalysisResponseModel(
      total: NutritionSummaryModel(
        estimatedCalories: totalCalories,
        protein: totalProtein,
        carbohydrates: totalCarbs,
        fat: totalFat,
        fiber: totalFiber,
      ),
      items: _editableItems,
      disclaimer: 'Data retrieved from Open Food Facts package information.',
    );
    _state = ScanState.reviewing;
    notifyListeners();
  }

  void reset() {
    _state = ScanState.initial;
    _selectedImage = null;
    _imageBytes = null;
    _analysisResult = null;
    _scannedProduct = null;
    _isLookingUpBarcode = false;
    _editableItems = [];
    _savedMeal = null;
    _errorMessage = null;
    notifyListeners();
  }
}

