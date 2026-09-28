import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Controller khusus untuk editor artikel yang mendukung live syntax highlighting /
/// rendering visual instan untuk format bold (**teks**), italic (*teks*),
/// underline (<u>teks</u>), dan heading (# teks).
class RichTextEditingController extends TextEditingController {
  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];
  bool _isUndoingOrRedoing = false;

  RichTextEditingController({super.text}) {
    _undoStack.add(value);
    addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    if (_isUndoingOrRedoing) return;
    if (_undoStack.isEmpty || _undoStack.last.text != value.text) {
      _undoStack.add(value);
      if (_undoStack.length > 50) {
        _undoStack.removeAt(0);
      }
      _redoStack.clear();
    }
  }

  bool get canUndo => _undoStack.length > 1;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (!canUndo) return;
    _isUndoingOrRedoing = true;
    _redoStack.add(_undoStack.removeLast());
    final prev = _undoStack.last;
    value = prev;
    _isUndoingOrRedoing = false;
  }

  void redo() {
    if (!canRedo) return;
    _isUndoingOrRedoing = true;
    final next = _redoStack.removeLast();
    _undoStack.add(next);
    value = next;
    _isUndoingOrRedoing = false;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final effectiveStyle = style ??
        GoogleFonts.lato(
          fontSize: 13.5,
          color: Colors.black,
          height: 1.45,
        );
    return parseRichTextDocument(text, effectiveStyle, isEditor: true);
  }
}

/// Parser teks yang mengubah tag markdown / HTML formatting menjadi [TextSpan].
///
/// Mendukung:
/// - Bold: `**teks**`
/// - Italic: `*teks*`
/// - Underline: `<u>teks</u>`
/// - Bold + Italic: `***teks***`
/// - Heading 1, 2, 3: `# `, `## `, `### `
TextSpan parseRichTextDocument(
  String text,
  TextStyle baseStyle, {
  required bool isEditor,
}) {
  if (text.isEmpty) return TextSpan(text: '', style: baseStyle);

  final lines = text.split('\n');
  final spans = <InlineSpan>[];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final isLast = i == lines.length - 1;

    TextStyle lineStyle = baseStyle;
    String content = line;

    if (line.startsWith('# ')) {
      lineStyle = baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 14.0) + 5.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      );
      if (!isEditor) {
        content = line.substring(2);
      }
    } else if (line.startsWith('## ')) {
      lineStyle = baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 14.0) + 3.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E293B),
      );
      if (!isEditor) {
        content = line.substring(3);
      }
    } else if (line.startsWith('### ')) {
      lineStyle = baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 14.0) + 1.5,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF334155),
      );
      if (!isEditor) {
        content = line.substring(4);
      }
    }

    spans.addAll(_buildInlineSpans(content, lineStyle, isEditor: isEditor));

    if (!isLast) {
      spans.add(const TextSpan(text: '\n'));
    }
  }

  return TextSpan(children: spans);
}

List<InlineSpan> _buildInlineSpans(
  String text,
  TextStyle baseStyle, {
  required bool isEditor,
}) {
  if (text.isEmpty) return const [];

  final spans = <InlineSpan>[];
  final regExp = RegExp(
    r'(\*\*\*(.+?)\*\*\*)|(\*\*(.+?)\*\*)|(\*([^\s*].*?)\*)|(<u>(.*?)<\/u>)',
    dotAll: true,
  );

  int lastIndex = 0;
  final markerStyle = TextStyle(
    color: const Color(0x38000000),
    fontSize: (baseStyle.fontSize ?? 13.0) * 0.85,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  for (final match in regExp.allMatches(text)) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(
        text: text.substring(lastIndex, match.start),
        style: baseStyle,
      ));
    }

    if (match.group(1) != null) {
      // Bold + Italic: ***text***
      final inner = match.group(2) ?? '';
      if (isEditor) {
        spans.add(TextSpan(text: '***', style: markerStyle));
      }
      final innerStyle = baseStyle.copyWith(
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      );
      spans.addAll(_buildInlineSpans(inner, innerStyle, isEditor: isEditor));
      if (isEditor) {
        spans.add(TextSpan(text: '***', style: markerStyle));
      }
    } else if (match.group(3) != null) {
      // Bold: **text**
      final inner = match.group(4) ?? '';
      if (isEditor) {
        spans.add(TextSpan(text: '**', style: markerStyle));
      }
      final innerStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
      spans.addAll(_buildInlineSpans(inner, innerStyle, isEditor: isEditor));
      if (isEditor) {
        spans.add(TextSpan(text: '**', style: markerStyle));
      }
    } else if (match.group(5) != null) {
      // Italic: *text*
      final inner = match.group(6) ?? '';
      if (isEditor) {
        spans.add(TextSpan(text: '*', style: markerStyle));
      }
      final innerStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
      spans.addAll(_buildInlineSpans(inner, innerStyle, isEditor: isEditor));
      if (isEditor) {
        spans.add(TextSpan(text: '*', style: markerStyle));
      }
    } else if (match.group(7) != null) {
      // Underline: <u>text</u>
      final inner = match.group(8) ?? '';
      if (isEditor) {
        spans.add(TextSpan(text: '<u>', style: markerStyle));
      }
      final innerStyle = baseStyle.copyWith(decoration: TextDecoration.underline);
      spans.addAll(_buildInlineSpans(inner, innerStyle, isEditor: isEditor));
      if (isEditor) {
        spans.add(TextSpan(text: '</u>', style: markerStyle));
      }
    }

    lastIndex = match.end;
  }

  if (lastIndex < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastIndex),
      style: baseStyle,
    ));
  }

  return spans;
}

/// Widget Rich Text Editor lengkap dengan toolbar aktif:
/// - Dropdown Paragraph / Heading (Heading 1, 2, 3)
/// - Bold (B), Italic (I), Underline (U) aktif
/// - List Bullet (•) & Numbered (1.)
/// - Undo & Redo
/// - TextField live-rendered
class ArticleRichTextEditor extends StatefulWidget {
  final RichTextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final int minLines;

  const ArticleRichTextEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    this.placeholder = 'Tulis isi berita di sini...',
    this.hasError = false,
    this.onChanged,
    this.minLines = 8,
  });

  @override
  State<ArticleRichTextEditor> createState() => _ArticleRichTextEditorState();
}

class _ArticleRichTextEditorState extends State<ArticleRichTextEditor> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  // Deteksi status format pada kursor/seleksi saat ini
  bool get _isBoldActive => _isFormatActive(prefix: '**', suffix: '**');
  bool get _isItalicActive => _isFormatActive(prefix: '*', suffix: '*');
  bool get _isUnderlineActive => _isFormatActive(prefix: '<u>', suffix: '</u>');

  String get _currentHeadingFormat {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    if (text.isEmpty) return 'p';

    final pos = sel.isValid ? sel.baseOffset.clamp(0, text.length) : text.length;
    final lineStart = text.lastIndexOf('\n', math.max(0, pos - 1)) + 1;
    final afterStart = text.substring(lineStart);

    if (afterStart.startsWith('### ')) return 'h3';
    if (afterStart.startsWith('## ')) return 'h2';
    if (afterStart.startsWith('# ')) return 'h1';
    return 'p';
  }

  bool _isFormatActive({required String prefix, required String suffix}) {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    if (!sel.isValid || text.isEmpty) return false;

    if (!sel.isCollapsed) {
      final start = sel.start.clamp(0, text.length);
      final end = sel.end.clamp(0, text.length);
      final selected = text.substring(start, end);
      return selected.startsWith(prefix) && selected.endsWith(suffix);
    }

    final pos = sel.baseOffset.clamp(0, text.length);
    final before = text.substring(0, pos);
    final after = text.substring(pos);

    final lastPrefix = before.lastIndexOf(prefix);
    final nextSuffix = after.indexOf(suffix);

    if (lastPrefix != -1 && nextSuffix != -1) {
      final betweenBefore = before.substring(lastPrefix + prefix.length);
      final betweenAfter = after.substring(0, nextSuffix);
      if (!betweenBefore.contains(suffix) && !betweenAfter.contains(prefix)) {
        return true;
      }
    }
    return false;
  }

  void _applyTextChange(
    String newText,
    int newCursorPos, {
    TextSelection? selection,
  }) {
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: selection ??
          TextSelection.collapsed(
            offset: newCursorPos.clamp(0, newText.length),
          ),
    );
    if (widget.onChanged != null) {
      widget.onChanged!(newText);
    }
  }

  void _toggleFormat({
    required String prefix,
    required String suffix,
    required String placeholder,
  }) {
    final text = widget.controller.text;
    final sel = widget.controller.selection;

    if (!sel.isValid) {
      final newText = '$text$prefix$placeholder$suffix';
      _applyTextChange(
        newText,
        newText.length,
        selection: TextSelection(
          baseOffset: text.length + prefix.length,
          extentOffset: text.length + prefix.length + placeholder.length,
        ),
      );
      widget.focusNode.requestFocus();
      return;
    }

    if (sel.isCollapsed) {
      final start = sel.start.clamp(0, text.length);
      final newText = text.replaceRange(start, start, '$prefix$placeholder$suffix');
      _applyTextChange(
        newText,
        start + prefix.length + placeholder.length,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: start + prefix.length + placeholder.length,
        ),
      );
    } else {
      final start = sel.start.clamp(0, text.length);
      final end = sel.end.clamp(0, text.length);
      final selectedText = text.substring(start, end);

      if (selectedText.startsWith(prefix) &&
          selectedText.endsWith(suffix) &&
          selectedText.length >= prefix.length + suffix.length) {
        // Hapus format
        final unformatted = selectedText.substring(
          prefix.length,
          selectedText.length - suffix.length,
        );
        final newText = text.replaceRange(start, end, unformatted);
        _applyTextChange(
          newText,
          start + unformatted.length,
          selection: TextSelection(
            baseOffset: start,
            extentOffset: start + unformatted.length,
          ),
        );
      } else {
        // Terapkan format
        final formatted = '$prefix$selectedText$suffix';
        final newText = text.replaceRange(start, end, formatted);
        _applyTextChange(
          newText,
          start + formatted.length,
          selection: TextSelection(
            baseOffset: start,
            extentOffset: start + formatted.length,
          ),
        );
      }
    }
    widget.focusNode.requestFocus();
  }

  void _setHeading(String headingType) {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    final pos = sel.isValid ? sel.baseOffset.clamp(0, text.length) : text.length;

    final lineStart = text.lastIndexOf('\n', math.max(0, pos - 1)) + 1;
    final lineEnd = text.indexOf('\n', pos);
    final actualLineEnd = lineEnd == -1 ? text.length : lineEnd;

    final currentLine = text.substring(lineStart, actualLineEnd);
    final cleanLine = currentLine.replaceFirst(RegExp(r'^#{1,3}\s*'), '');

    String newLine;
    switch (headingType) {
      case 'h1':
        newLine = '# $cleanLine';
        break;
      case 'h2':
        newLine = '## $cleanLine';
        break;
      case 'h3':
        newLine = '### $cleanLine';
        break;
      default:
        newLine = cleanLine;
        break;
    }

    final newText = text.replaceRange(lineStart, actualLineEnd, newLine);
    _applyTextChange(newText, lineStart + newLine.length);
    widget.focusNode.requestFocus();
  }

  void _toggleLinePrefix(String prefix) {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    final pos = sel.isValid ? sel.baseOffset.clamp(0, text.length) : text.length;

    final lineStart = text.lastIndexOf('\n', math.max(0, pos - 1)) + 1;
    final lineEnd = text.indexOf('\n', pos);
    final actualLineEnd = lineEnd == -1 ? text.length : lineEnd;

    final currentLine = text.substring(lineStart, actualLineEnd);
    String newLine;
    if (currentLine.startsWith(prefix)) {
      newLine = currentLine.substring(prefix.length);
    } else {
      newLine = '$prefix$currentLine';
    }

    final newText = text.replaceRange(lineStart, actualLineEnd, newLine);
    _applyTextChange(newText, lineStart + newLine.length);
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? const Color(0xFFE53935)
        : const Color(0xFFD1D5DB);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------------------------------------------------
          // TOOLBAR EDITOR (Dropdown, Bold, Italic, Underline, List, Undo, Redo)
          // -------------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.0)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Dropdown Paragraph / Heading
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currentHeadingFormat,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18.0,
                        color: Color(0xFF4B5563),
                      ),
                      isDense: true,
                      style: GoogleFonts.lato(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'p',
                          child: Text('Paragraph'),
                        ),
                        DropdownMenuItem(
                          value: 'h1',
                          child: Text('Heading 1'),
                        ),
                        DropdownMenuItem(
                          value: 'h2',
                          child: Text('Heading 2'),
                        ),
                        DropdownMenuItem(
                          value: 'h3',
                          child: Text('Heading 3'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) _setHeading(val);
                      },
                    ),
                  ),

                  _buildVerticalDivider(),

                  // Tombol Bold (B) Aktif
                  _ToolbarButton(
                    isActive: _isBoldActive,
                    tooltip: 'Tebal (Bold)',
                    onTap: () => _toggleFormat(
                      prefix: '**',
                      suffix: '**',
                      placeholder: 'teks tebal',
                    ),
                    child: Text(
                      'B',
                      style: GoogleFonts.lato(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: _isBoldActive
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4.0),

                  // Tombol Italic (I) Aktif
                  _ToolbarButton(
                    isActive: _isItalicActive,
                    tooltip: 'Miring (Italic)',
                    onTap: () => _toggleFormat(
                      prefix: '*',
                      suffix: '*',
                      placeholder: 'teks miring',
                    ),
                    child: Text(
                      'I',
                      style: GoogleFonts.lato(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: _isItalicActive
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4.0),

                  // Tombol Underline (U) Aktif
                  _ToolbarButton(
                    isActive: _isUnderlineActive,
                    tooltip: 'Garis Bawah (Underline)',
                    onTap: () => _toggleFormat(
                      prefix: '<u>',
                      suffix: '</u>',
                      placeholder: 'teks bergaris bawah',
                    ),
                    child: Text(
                      'U',
                      style: GoogleFonts.lato(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: _isUnderlineActive
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4.0),

                  // Tombol Bullet List (:=)
                  _ToolbarButton(
                    tooltip: 'Daftar Poin (Bullet List)',
                    onTap: () => _toggleLinePrefix('• '),
                    child: const Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 19.0,
                      color: Color(0xFF4B5563),
                    ),
                  ),

                  const SizedBox(width: 4.0),

                  // Tombol Numbered List (1.=)
                  _ToolbarButton(
                    tooltip: 'Daftar Bernomor (Numbered List)',
                    onTap: () => _toggleLinePrefix('1. '),
                    child: const Icon(
                      Icons.format_list_numbered_rounded,
                      size: 19.0,
                      color: Color(0xFF4B5563),
                    ),
                  ),

                  _buildVerticalDivider(),

                  // Tombol Undo (↩)
                  _ToolbarButton(
                    tooltip: 'Undo',
                    onTap: widget.controller.canUndo
                        ? () => widget.controller.undo()
                        : null,
                    child: Icon(
                      Icons.undo_rounded,
                      size: 18.0,
                      color: widget.controller.canUndo
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),

                  const SizedBox(width: 4.0),

                  // Tombol Redo (↪)
                  _ToolbarButton(
                    tooltip: 'Redo',
                    onTap: widget.controller.canRedo
                        ? () => widget.controller.redo()
                        : null,
                    child: Icon(
                      Icons.redo_rounded,
                      size: 18.0,
                      color: widget.controller.canRedo
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------
          // AREA INPUT TEKS MULTI-LINE (Live Styled)
          // -------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              maxLines: null,
              minLines: widget.minLines,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.lato(
                fontSize: 13.5,
                color: Colors.black,
                height: 1.45,
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: GoogleFonts.lato(
                  fontSize: 13.5,
                  color: const Color(0xFF9E9E9E),
                  fontWeight: FontWeight.normal,
                  height: 1.45,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1.0,
      height: 20.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      color: const Color(0xFFE5E7EB),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final Widget child;
  final bool isActive;
  final VoidCallback? onTap;
  final String? tooltip;

  const _ToolbarButton({
    required this.child,
    this.isActive = false,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: isActive ? const Color(0xFFEBF3FE) : Colors.transparent,
        borderRadius: BorderRadius.circular(6.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6.0),
          child: Container(
            width: 32.0,
            height: 30.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: isActive ? const Color(0xFF93C5FD) : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan teks artikel yang sudah diformat (Bold, Italic,
/// Underline, Heading) pada halaman pembaca (seperti [DetailArtikelPage]).
class FormattedArticleText extends StatelessWidget {
  final String content;
  final TextStyle? style;
  final TextAlign textAlign;

  const FormattedArticleText({
    super.key,
    required this.content,
    this.style,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        GoogleFonts.lato(
          fontSize: 15.0,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: const Color(0xFF262626),
        );

    return Text.rich(
      parseRichTextDocument(content, baseStyle, isEditor: false),
      textAlign: textAlign,
    );
  }
}
