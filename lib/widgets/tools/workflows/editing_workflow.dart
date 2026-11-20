import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../../../core/models/tool_definition.dart';
import '../../../core/state/studio_scope.dart';
import '../../../services/pdf/editing/pdf_attachment_service.dart';
import '../../../services/pdf/optimization/pdf_image_service.dart';
import '../../../services/pdf/editing/pdf_mark_service.dart';
import '../../../services/pdf/editing/pdf_page_box_service.dart';
import '../../../services/pdf/editing/pdf_metadata_service.dart';
import '../../../services/pdf/editing/pdf_redaction_service.dart';
import '../../../services/pdf/security/pdf_sanitize_service.dart';
import 'tool_workflow.dart';
import 'workflow_output.dart';

class EditingWorkflow implements ToolWorkflow {
  final _marks = PdfMarkService();
  final _boxes = PdfPageBoxService();
  final _metadata = PdfMetadataService();
  final _redaction = PdfRedactionService();
  final _attachments = PdfAttachmentService();
  final _images = PdfImageService();
  final _sanitize = PdfSanitizeService();

  @override
  Future<void> run(BuildContext context, ToolDefinition tool, String value) async {
    final controller = StudioScope.read(context);
    final bytes = controller.activeDocumentBytes!;
    switch (tool.id) {
      case 'watermark':
        final parts = value.split('|');
        final text = parts.first.trim();
        if (text.isEmpty) {
          throw const FormatException('Enter the watermark text.');
        }
        final size = parts.length > 1 ? double.tryParse(parts[1]) ?? 48 : 48;
        final color = parts.length > 2
            ? int.tryParse(parts[2]) ?? 0xFF808080
            : 0xFF808080;
        final opacity = parts.length > 3
            ? double.tryParse(parts[3]) ?? 0.3
            : 0.3;
        await _update(
          context,
          await _marks.watermark(
            bytes,
            text,
            fontSize: size.clamp(8, 144).toDouble(),
            color: color,
            opacity: opacity.clamp(0.05, 1).toDouble(),
          ),
        );
        break;
      case 'stamp':
        final stamp = switch (value.toLowerCase()) {
          'approved' => PdfStamp.approved,
          'confidential' => PdfStamp.confidential,
          _ => PdfStamp.draft,
        };
        await _update(context, await _marks.stamp(bytes, stamp));
        break;
      case 'imagestamp':
        final image = await controller.files.pickFile(['png', 'jpg', 'jpeg']);
        if (image != null) await _update(context, await _marks.imageStamp(bytes, image.bytes));
        break;
      case 'attachment':
        final file = await controller.files.pickAnyFile();
        if (file != null) await _update(context, await _attachments.add(bytes, file.name, file.bytes));
        break;
      case 'crop':
        final values = _numbers(value, 4);
        if (values.any((margin) => !margin.isFinite || margin < 0 || margin > 180)) {
          throw const FormatException(
            'Crop margins must be between 0 and 180 points.',
          );
        }
        await _update(
          context,
          await _boxes.cropMargins(
            bytes,
            top: values[0],
            right: values[1],
            bottom: values[2],
            left: values[3],
          ),
        );
        break;
      case 'resize':
        final values = _numbers(value, 2);
        await _update(context, await _boxes.resize(bytes, values[0], values[1]));
        break;
      case 'metadata':
        await _update(context, await _metadata.update(bytes, PdfMetadata(title: value)));
        break;
      case 'redact':
        final values = _numbers(value, 5);
        final rect = PdfRect(x: values[1], y: values[2], width: values[3], height: values[4]);
        await _update(context, await _redaction.redact(bytes, values[0].toInt() - 1, [rect]));
        break;
      case 'moveimage':
        final parts = value.split(',');
        if (parts.length != 6) throw const FormatException('Use page,imageName,x,y,width,height.');
        final rect = PdfRect(x: double.parse(parts[2]), y: double.parse(parts[3]), width: double.parse(parts[4]), height: double.parse(parts[5]));
        await _update(context, await _images.moveImage(bytes, int.parse(parts[0]) - 1, parts[1], rect));
        break;
      case 'flattenforms':
        await _update(context, await _sanitize.flattenForms(bytes));
        break;
      case 'flattenannotations':
        await _update(context, await _sanitize.flattenAnnotations(bytes));
        break;
    }
  }

  List<double> _numbers(String value, int count) {
    final values = value.split(',').map((part) => double.parse(part.trim())).toList();
    if (values.length != count) throw FormatException('Enter $count comma-separated numbers.');
    return values;
  }

  Future<void> _update(BuildContext context, Uint8List bytes) => WorkflowOutput.updateCurrent(context, bytes);
}
