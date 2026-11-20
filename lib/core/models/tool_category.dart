enum ToolCategory {
  organize('Organize PDF', 'Arrange, split and combine pages', 'organize'),
  edit('Edit PDF', 'Modify pages and document content', 'edit'),
  convert('Convert PDF', 'Convert between PDF and Office formats', 'convert'),
  security('PDF security', 'Protect, sign and sanitize documents', 'security'),
  optimize('Optimize PDF', 'Compress and reduce file size', 'optimize'),
  read('Read & analyze', 'Extract text, images and document data', 'read'),
  forms('PDF forms', 'Inspect, fill and flatten forms', 'forms'),
  create('Create PDF', 'Build documents and image-based PDFs', 'create'),
  standards('PDF standards', 'Validate and convert PDF standards', 'standards');

  const ToolCategory(this.title, this.subtitle, this.localizationKey);
  final String title;
  final String subtitle;
  final String localizationKey;

  String get titleKey => 'category.$localizationKey';
  String get subtitleKey => 'category.${localizationKey}_sub';
}
