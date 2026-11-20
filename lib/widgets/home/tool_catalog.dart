import 'package:flutter/material.dart';
import 'tool_card.dart';

class ToolEntry {
  const ToolEntry(
    this.title,
    this.description,
    this.icon,
    this.action, {
    this.group = 'Popular tools',
  });
  final String title;
  final String description;
  final IconData icon;
  final String action;
  final String group;
}

const toolEntries = <ToolEntry>[
  ToolEntry(
    'Merge PDF',
    'Combine PDFs in the order you choose.',
    Icons.call_merge,
    'merge',
  ),
  ToolEntry(
    'Append PDF',
    'Add pages from another PDF.',
    Icons.playlist_add,
    'append',
  ),
  ToolEntry(
    'Split PDF',
    'Divide a document into smaller files.',
    Icons.content_cut,
    'split',
  ),
  ToolEntry(
    'Compress PDF',
    'Reduce file size while preserving quality.',
    Icons.compress,
    'compress',
  ),
  ToolEntry(
    'Rotate PDF',
    'Rotate one page or the entire document.',
    Icons.rotate_right,
    'rotate',
  ),
  ToolEntry(
    'Remove pages',
    'Delete pages you no longer need.',
    Icons.delete_outline_rounded,
    'remove',
  ),
  ToolEntry(
    'Extract pages',
    'Keep only the pages you select.',
    Icons.file_copy,
    'extract',
  ),
  ToolEntry(
    'Reorder pages',
    'Set a new page order.',
    Icons.swap_vert_rounded,
    'reorder',
  ),
  ToolEntry(
    'Watermark PDF',
    'Add a text watermark to pages.',
    Icons.branding_watermark_sharp,
    'watermark',
  ),
  ToolEntry(
    'Add stamp',
    'Apply Draft, Approved or Confidential.',
    Icons.verified,
    'stamp',
  ),
  ToolEntry(
    'Image stamp',
    'Place a logo or image on pages.',
    Icons.add_photo_alternate,
    'imagestamp',
  ),
  ToolEntry(
    'Add attachment',
    'Embed a file inside the PDF.',
    Icons.attach_file,
    'attachment',
  ),
  ToolEntry(
    'Crop margins',
    'Trim margins from every page.',
    Icons.crop,
    'crop',
  ),
  ToolEntry(
    'Crop to box',
    'Set a precise visible page rectangle.',
    Icons.crop_free,
    'cropbox',
  ),
  ToolEntry(
    'Resize pages',
    'Change the physical page dimensions.',
    Icons.aspect_ratio_rounded,
    'resize',
  ),
  ToolEntry(
    'Remove standard fonts',
    'Unembed standard font copies.',
    Icons.font_download,
    'unembedfonts',
  ),
  ToolEntry(
    'Redact content',
    'Permanently remove a page region.',
    Icons.highlight_off,
    'redact',
  ),
  ToolEntry(
    'Extract text',
    'Read searchable text from the PDF.',
    Icons.text_snippet,
    'text',
    group: 'Read and analyse',
  ),
  ToolEntry(
    'Search PDF',
    'Find text and matching page locations.',
    Icons.manage_search,
    'search',
    group: 'Read and analyse',
  ),
  ToolEntry(
    'Document info',
    'Inspect PDF version, metadata and encryption.',
    Icons.info_outline,
    'info',
    group: 'Read and analyse',
  ),
  ToolEntry(
    'Page information',
    'Inspect page dimensions and rotation.',
    Icons.straighten,
    'pageinfo',
    group: 'Read and analyse',
  ),
  ToolEntry(
    'Inspect bookmarks',
    'Read top-level bookmark page ranges.',
    Icons.bookmarks,
    'bookmarks',
    group: 'Read and analyse',
  ),
  ToolEntry(
    'Inspect annotations',
    'List annotations on a selected page.',
    Icons.comment,
    'annotations',
    group: 'Read and analyse',
  ),
  ToolEntry(
    'Extract images',
    'Save embedded images from the PDF.',
    Icons.image_search,
    'extractimages',
    group: 'Read and analyse',
  ),
  ToolEntry(
    'Render page to PNG',
    'Export one rendered page image.',
    Icons.image,
    'renderpage',
    group: 'Read and analyse',
  ),
  ToolEntry(
    'Render all pages',
    'Export every page as a PNG image.',
    Icons.collections,
    'renderall',
    group: 'Read and analyse',
  ),
  ToolEntry(
    'Extract attachments',
    'Save an embedded file attachment.',
    Icons.file_download,
    'attachments',
    group: 'Read and analyse',
  ),
  ToolEntry(
    'Inspect forms',
    'List interactive form fields.',
    Icons.dynamic_form,
    'forms',
    group: 'Forms and security',
  ),
  ToolEntry(
    'Inspect XFA data',
    'Read the XFA packet information.',
    Icons.code,
    'xfainfo',
    group: 'Forms and security',
  ),
  ToolEntry(
    'Export form data',
    'Export form values as XFDF.',
    Icons.output,
    'formexport',
    group: 'Forms and security',
  ),
  ToolEntry(
    'Flatten forms',
    'Make form fields non-interactive.',
    Icons.layers,
    'flattenforms',
    group: 'Forms and security',
  ),
  ToolEntry(
    'Fill form field',
    'Set a value in an AcroForm field.',
    Icons.edit,
    'fillform',
    group: 'Forms and security',
  ),
  ToolEntry(
    'Encrypt PDF',
    'Protect a PDF with a password.',
    Icons.lock_outline,
    'encrypt',
    group: 'Forms and security',
  ),
  ToolEntry(
    'Decrypt PDF',
    'Remove password protection.',
    Icons.lock_open,
    'decrypt',
    group: 'Forms and security',
  ),
  ToolEntry(
    'Sanitize PDF',
    'Remove metadata, scripts and attachments.',
    Icons.cleaning_services,
    'sanitize',
    group: 'Forms and security',
  ),
  ToolEntry(
    'Sign PDF',
    'Apply a PKCS#12 digital signature.',
    Icons.draw,
    'sign',
    group: 'Forms and security',
  ),
  ToolEntry(
    'Verify signatures',
    'Inspect and verify digital signatures.',
    Icons.verified_user,
    'signatures',
    group: 'Forms and security',
  ),
  ToolEntry(
    'PDF to DOCX',
    'Convert a PDF into a Word document.',
    Icons.description,
    'docx',
    group: 'Convert PDF',
  ),
  ToolEntry(
    'PDF to PPTX',
    'Convert a PDF into a presentation.',
    Icons.slideshow,
    'pptx',
    group: 'Convert PDF',
  ),
  ToolEntry(
    'PDF to XLSX',
    'Convert a PDF into a spreadsheet.',
    Icons.table_chart,
    'xlsx',
    group: 'Convert PDF',
  ),
  ToolEntry(
    'Convert XFA forms',
    'Convert XFA forms to AcroForms.',
    Icons.transform,
    'xfa',
    group: 'Convert PDF',
  ),
  ToolEntry(
    'Office to PDF',
    'Convert a DOCX, PPTX or XLSX file.',
    Icons.insert_drive_file_outlined,
    'officetopdf',
    group: 'Convert PDF',
  ),
  ToolEntry(
    'Images to PDF',
    'Create a PDF from image files.',
    Icons.image,
    'imagestopdf',
    group: 'Create PDF',
  ),
  ToolEntry(
    'Validate PDF/A',
    'Check archival PDF conformance.',
    Icons.fact_check,
    'pdfa',
    group: 'PDF standards',
  ),
  ToolEntry(
    'Validate PDF/UA',
    'Check accessibility conformance.',
    Icons.accessibility_new,
    'pdfua',
    group: 'PDF standards',
  ),
  ToolEntry(
    'Convert to PDF/A',
    'Convert the document to PDF/A.',
    Icons.archive,
    'convertpdfa',
    group: 'PDF standards',
  ),
  ToolEntry(
    'Create PDF',
    'Create a PDF from text content.',
    Icons.note_add,
    'create',
    group: 'Create PDF',
  ),
  ToolEntry(
    'Create table PDF',
    'Generate a PDF containing a table.',
    Icons.table_chart,
    'createtable',
    group: 'Create PDF',
  ),
  ToolEntry(
    'Create fillable form',
    'Generate a PDF with interactive fields.',
    Icons.dynamic_form,
    'createform',
    group: 'Create PDF',
  ),
  ToolEntry(
    'Create image page',
    'Place an image on a new PDF page.',
    Icons.add_photo_alternate,
    'createimagepage',
    group: 'Create PDF',
  ),
];

class ToolCatalog extends StatelessWidget {
  const ToolCatalog({super.key, required this.onTool, this.group});
  final ValueChanged<ToolEntry> onTool;
  final String? group;

  @override
  Widget build(BuildContext context) {
    final groups = group == null
        ? toolEntries.map((entry) => entry.group).toSet()
        : {group!};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final name in groups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF292D33),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1050
                  ? 4
                  : constraints.maxWidth > 680
                  ? 3
                  : constraints.maxWidth > 440
                  ? 2
                  : 1;
              final entries = toolEntries
                  .where((entry) => entry.group == name)
                  .toList();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 132,
                ),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ToolCard(
                    title: entry.title,
                    description: entry.description,
                    icon: entry.icon,
                    onTap: () => onTool(entry),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }
}
