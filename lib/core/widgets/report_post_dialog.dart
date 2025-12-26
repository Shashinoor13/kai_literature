import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/models/report_reason.dart';

/// Bottom sheet for reporting a post with various reasons
class ReportPostDialog extends StatefulWidget {
  final Function(ReportReason reason, String? details) onReport;

  const ReportPostDialog({
    super.key,
    required this.onReport,
  });

  @override
  State<ReportPostDialog> createState() => _ReportPostDialogState();
}

class _ReportPostDialogState extends State<ReportPostDialog> {
  ReportReason? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (_selectedReason == null) return;

    setState(() {
      _isSubmitting = true;
    });

    widget.onReport(
      _selectedReason!,
      _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                const HeroIcon(
                  HeroIcons.flag,
                  style: HeroIconStyle.outline,
                  size: 24,
                  color: Colors.white,
                ),
                const SizedBox(width: AppSizes.sm),
                const Expanded(
                  child: Text(
                    'Report Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const HeroIcon(
                    HeroIcons.xMark,
                    style: HeroIconStyle.outline,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Reason selection
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Why are you reporting this post?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Reason options
                  ...ReportReason.values.map((reason) {
                    return _ReasonOption(
                      reason: reason,
                      isSelected: _selectedReason == reason,
                      onTap: () {
                        setState(() {
                          _selectedReason = reason;
                        });
                      },
                    );
                  }),

                  const SizedBox(height: AppSizes.lg),

                  // Additional details (optional)
                  const Text(
                    'Additional details (optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  TextField(
                    controller: _detailsController,
                    maxLines: 3,
                    maxLength: 500,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Provide more context about this report...',
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      filled: true,
                      fillColor: Colors.white12,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusSm,
                        ),
                        borderSide: const BorderSide(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusSm,
                        ),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSizes.sm,
                        horizontal: AppSizes.md,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            padding: const EdgeInsets.all(AppSizes.md),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white38,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  ElevatedButton(
                    onPressed: _isSubmitting || _selectedReason == null
                        ? null
                        : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white24,
                      disabledForegroundColor: Colors.white38,
                      minimumSize: const Size(100, AppSizes.buttonHeight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusSm,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text('Submit Report'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual reason option widget
class _ReasonOption extends StatelessWidget {
  final ReportReason reason;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReasonOption({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          color: isSelected ? Colors.white12 : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio button indicator
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white38,
                  width: 2,
                ),
                color: Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      color: Colors.white,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
