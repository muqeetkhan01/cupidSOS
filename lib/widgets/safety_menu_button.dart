import 'dart:io';

import 'package:cupid_app/services/auth_service.dart';
import 'package:cupid_app/services/safety_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class SafetyMenuButton extends StatelessWidget {
  const SafetyMenuButton({
    super.key,
    required this.currentUid,
    required this.targetUid,
    this.threadId,
    this.showUnmatch = false,
    this.icon = Icons.more_horiz_rounded,
    this.onCompleted,
    this.onOpenSafetyCenter,
  });

  final String currentUid;
  final String targetUid;
  final String? threadId;
  final bool showUnmatch;
  final IconData icon;
  final VoidCallback? onCompleted;
  final VoidCallback? onOpenSafetyCenter;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(icon, color: Colors.black87),
      onSelected: (value) async {
        if (value == 'report') {
          await _showReportSheet(context);
          return;
        }
        if (value == 'block') {
          await _showBlockDialog(context);
          return;
        }
        if (value == 'unmatch') {
          await _showUnmatchDialog(context);
          return;
        }
        if (value == 'safety') {
          onOpenSafetyCenter?.call();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'report', child: Text('Report')),
        const PopupMenuItem(value: 'block', child: Text('Block')),
        if (showUnmatch)
          const PopupMenuItem(value: 'unmatch', child: Text('Unmatch')),
        const PopupMenuItem(value: 'safety', child: Text('Safety Center')),
      ],
    );
  }

  Future<void> _showBlockDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Block this user?'),
          content: const Text('You won’t see each other anymore.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await SafetyService.instance.blockUser(
                  currentUid: currentUid,
                  targetUid: targetUid,
                  threadId: threadId,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _showDone(context, 'User blocked. You won’t see them again.');
                onCompleted?.call();
              },
              child: const Text('Block & remove match'),
            ),
            FilledButton(
              onPressed: () async {
                await SafetyService.instance.reportUser(
                  reporterUid: currentUid,
                  targetUid: targetUid,
                  threadId: threadId,
                  reason: 'Blocked from safety menu',
                );
                await SafetyService.instance.blockUser(
                  currentUid: currentUid,
                  targetUid: targetUid,
                  threadId: threadId,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _showDone(context, 'User blocked and reported.');
                onCompleted?.call();
              },
              child: const Text('Block & report'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUnmatchDialog(BuildContext context) async {
    var hideAgain = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: const Text('Unmatch this user?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('This will remove the connection.'),
                  ),
                  SizedBox(height: 1.h),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: hideAgain,
                    onChanged: (value) =>
                        setState(() => hideAgain = value ?? false),
                    title: const Text('Don’t show me again'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    await SafetyService.instance.unmatchUser(
                      currentUid: currentUid,
                      targetUid: targetUid,
                      threadId: threadId,
                      hideThread: true,
                    );
                    if (hideAgain) {
                      await SafetyService.instance.blockUser(
                        currentUid: currentUid,
                        targetUid: targetUid,
                        threadId: threadId,
                        removeMatch: false,
                      );
                    }
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    _showDone(context, 'Connection removed.');
                    onCompleted?.call();
                  },
                  child: const Text('Unmatch'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showReportSheet(BuildContext context) async {
    final detailsCtrl = TextEditingController();
    String reason = 'Fake profile';
    final picker = ImagePicker();
    final screenshots = <File>[];
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (_, setState) {
            const reasons = <String>[
              'Fake profile',
              'Inappropriate messages',
              'Harassment or bullying',
              'Scam or spam',
              'Offensive content',
              'Something else',
            ];

            Future<void> submit({required bool alsoBlock}) async {
              setState(() => submitting = true);
              final screenshotUrls = <String>[];
              for (final image in screenshots) {
                final url = await AuthService.to.uploadProfileImage(image);
                if (url != null && url.trim().isNotEmpty) {
                  screenshotUrls.add(url.trim());
                }
              }
              await SafetyService.instance.reportUser(
                reporterUid: currentUid,
                targetUid: targetUid,
                threadId: threadId,
                reason: reason,
                details: detailsCtrl.text,
                screenshotUrls: screenshotUrls,
              );
              if (alsoBlock) {
                await SafetyService.instance.blockUser(
                  currentUid: currentUid,
                  targetUid: targetUid,
                  threadId: threadId,
                );
              }
              if (sheetContext.mounted) Navigator.pop(sheetContext);
              _showDone(
                context,
                alsoBlock
                    ? 'Thanks for helping keep Cupid SOS safe.'
                    : 'Report submitted. We’ll review it shortly.',
              );
              onCompleted?.call();
            }

            Future<void> addScreenshot() async {
              final picked =
                  await picker.pickImage(source: ImageSource.gallery);
              if (picked == null) return;
              setState(() => screenshots.add(File(picked.path)));
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                6.w,
                2.5.h,
                6.w,
                MediaQuery.of(sheetContext).viewInsets.bottom + 2.5.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What’s going on?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 1.8.h),
                  for (final item in reasons)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item),
                      value: item,
                      groupValue: reason,
                      onChanged: (value) =>
                          setState(() => reason = value ?? reason),
                    ),
                  SizedBox(height: 1.h),
                  TextField(
                    controller: detailsCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tell us more (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  OutlinedButton.icon(
                    onPressed: submitting ? null : addScreenshot,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      screenshots.isEmpty
                          ? 'Add screenshots'
                          : 'Screenshots (${screenshots.length})',
                    ),
                  ),
                  if (screenshots.isNotEmpty) ...[
                    SizedBox(height: 1.2.h),
                    SizedBox(
                      height: 9.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, index) => ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            screenshots[index],
                            width: 20.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                        separatorBuilder: (_, __) => SizedBox(width: 3.w),
                        itemCount: screenshots.length,
                      ),
                    ),
                  ],
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: submitting
                              ? null
                              : () => submit(alsoBlock: false),
                          child:
                              Text(submitting ? 'Sending...' : 'Report only'),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: FilledButton(
                          onPressed:
                              submitting ? null : () => submit(alsoBlock: true),
                          child: Text(
                            submitting ? 'Sending...' : 'Report & block',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    detailsCtrl.dispose();
  }

  void _showDone(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
