import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_client.dart';
import '../../core/widgets/barcode_result_dialog.dart';
import '../../core/widgets/custom_button.dart';
import '../manual/manual_food_entry_view.dart';
import 'analysis_review_view.dart';
import 'scan_view_model.dart';

class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  int _selectedTabIndex = 0; // 0: AI Plate Photo, 1: Barcode Scan, 2: Manual Entry
  final TextEditingController _barcodeController = TextEditingController();

  final List<Map<String, String>> _sampleBarcodes = const [
    {'code': '737628064502', 'title': 'Rolled Oats (Bob\'s)'},
    {'code': '3017620422003', 'title': 'Nutella'},
    {'code': '5449000000996', 'title': 'Coca-Cola'},
    {'code': '073852002029', 'title': 'Chobani Yogurt'},
    {'code': '7622210449283', 'title': 'Oreo Cookies'},
  ];

  @override
  void initState() {
    super.initState();
    // Warm up backend connection in background so scan is fast
    ApiClient().prewarm();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _handlePick(BuildContext context, ImageSource source) async {
    final scanVm = context.read<ScanViewModel>();
    await scanVm.pickAndAnalyze(source);

    if (context.mounted) {
      if (scanVm.state == ScanState.reviewing) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalysisReviewView()),
        );
      } else if (scanVm.state == ScanState.error && scanVm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(scanVm.errorMessage!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _handleBarcodeSearch(BuildContext context, String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;

    final scanVm = context.read<ScanViewModel>();
    final product = await scanVm.lookupBarcode(cleanCode);

    if (!context.mounted) return;

    if (product != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BarcodeResultDialog(
          product: product,
          onAddToPlate: (p, multiplier) {
            scanVm.addBarcodeProductToPlate(p, multiplier: multiplier);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalysisReviewView()),
            );
          },
        ),
      );
    } else if (scanVm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scanVm.errorMessage!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanVm = context.watch<ScanViewModel>();

    if (scanVm.state == ScanState.analyzing) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (scanVm.imageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      scanVm.imageBytes!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Gemini AI is analyzing your food...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Identifying ingredients and calculating estimated portions & macros.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),
                OutlinedButton.icon(
                  onPressed: () => scanVm.cancelAnalysis(),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                  label: const Text(
                    'Cancel Analysis',
                    style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Food'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      index: 0,
                      label: 'AI Photo',
                      icon: Icons.camera_alt_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      index: 1,
                      label: 'Barcode',
                      icon: Icons.qr_code_scanner_rounded,
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      index: 2,
                      label: 'Manual',
                      icon: Icons.edit_note_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _selectedTabIndex == 0
            ? _buildPhotoScanBody(context)
            : (_selectedTabIndex == 1
                ? _buildBarcodeScanBody(context, scanVm)
                : const ManualFoodEntryView()),
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoScanBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_enhance_rounded,
              size: 72,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Snap Your Plate',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Take a photo or upload an image of your meal. Our AI will identify the foods and estimate nutrition breakdown.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48),
          CustomButton(
            text: 'Take Photo',
            icon: Icons.camera_alt,
            onPressed: () => _handlePick(context, ImageSource.camera),
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: 'Choose from Gallery',
            icon: Icons.photo_library_outlined,
            isOutlined: true,
            onPressed: () => _handlePick(context, ImageSource.gallery),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _selectedTabIndex = 2),
            icon: const Icon(Icons.edit_note, color: AppTheme.primaryDark),
            label: const Text(
              'Or enter food manually with custom values ✍️',
              style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeScanBody(BuildContext context, ScanViewModel scanVm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Viewfinder Frame Graphic
          Center(
            child: Container(
              width: 220,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 64,
                    color: Colors.white54,
                  ),
                  // Red laser scan line
                  Container(
                    width: 180,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Scan Packaged Foods',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter or scan a barcode to instantly pull verified nutrition, Nutri-Score, and ingredients from Open Food Facts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Barcode input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter barcode (e.g. 737628064502)',
                    prefixIcon: const Icon(Icons.barcode_reader, color: AppTheme.primaryGreen),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                    ),
                  ),
                  onSubmitted: (val) => _handleBarcodeSearch(context, val),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: scanVm.isLookingUpBarcode
                    ? null
                    : () => _handleBarcodeSearch(context, _barcodeController.text),
                child: scanVm.isLookingUpBarcode
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Presets
          const Text(
            'Try Sample Barcodes:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sampleBarcodes.map((sample) {
              return ActionChip(
                backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.6),
                avatar: const Icon(Icons.qr_code, size: 16, color: AppTheme.primaryDark),
                label: Text(
                  sample['title']!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
                onPressed: () {
                  _barcodeController.text = sample['code']!;
                  _handleBarcodeSearch(context, sample['code']!);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
