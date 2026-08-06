import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../state/media_viewer_state.dart';

class DocItemViewer extends ConsumerStatefulWidget {
  final VaultItemEntity item;

  const DocItemViewer({super.key, required this.item});

  @override
  ConsumerState<DocItemViewer> createState() => _DocItemViewerState();
}

class _DocItemViewerState extends ConsumerState<DocItemViewer> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(playbackSessionProvider(widget.item));

    return Center(
      child: sessionState.when(
        data: (session) {
          if (widget.item.originalName.endsWith('.txt')) {
             return _buildTextEditor(session.file);
          }
          
          return SfPdfViewer.file(
            session.file,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            canShowScrollHead: true,
            canShowScrollStatus: true,
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (e, st) => Text('Error loading doc: $e', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
  
  Widget _buildTextEditor(File file) {
    // A simple mock for the encrypted text editor
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: const TextField(
        maxLines: null,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Start typing your secure note...',
        ),
      ),
    );
  }
}
