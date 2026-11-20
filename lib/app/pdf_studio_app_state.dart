import 'package:flutter/material.dart';

import '../core/state/studio_controller.dart';
import 'pdf_studio_app.dart';

class PdfStudioAppState extends State<PdfStudioApp> {
  late final StudioController _controller = createStudioController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildPdfStudioApp(context, _controller);
}
