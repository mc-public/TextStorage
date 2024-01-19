//
//  fredbuf-tree-sitter.c
//
//
//  Created by mc-public on 2024/1/18.
//

#import "fredbuf-tree-sitter.h"
#import "../fredbuf/encoding.h"
#import "../tree-sitter/src/atomic.h"
#import <assert.h>


using namespace PieceTree;

/* ---- ASSUME SINGLE THREAD ---- */
/* --- ASSUME UTF-16 ENCODING --- */

//MARK: - Parser Operation

/// Initialize a `tree_sitter_parser` object.
inline tree_sitter_parser *fredbuf_ts_parser_init(Tree *piece_tree)
{
    tree_sitter_parser *parser = (tree_sitter_parser*)malloc(sizeof(TSParser*) + sizeof(Tree*) + sizeof(char*) + sizeof(size_t*));
    size_t *cancel_flag = (size_t*)malloc(sizeof(size_t));
    __atomic_store_n((volatile uint32_t*)cancel_flag, 0U, __ATOMIC_SEQ_CST);
    *parser = {
        ts_parser_new(),
        piece_tree,
        NULL,
        cancel_flag
    };
    return parser;
}

/// Delete a `tree_sitter_parser` object and free memory(except `Tree` object).
inline void fredbuf_ts_parser_free(tree_sitter_parser *self)
{
    ts_parser_delete(self->parser);
    if (self->input_char) {
        free(self->input_char);
    }
    if (self->cancel_flag) {
        free((void*)self->cancel_flag);
    }
}

/// Set the parsing language for a `TSParser` object.
///
/// - Parameter self: A pointer points to a `TSParser` object.
/// - Parameter language: A pointer points to a `TSLanguage` object.
///
/// - Returns: A boolean value indicating whether or not the language was successfully assigned. `False` means there was a version mismatch, the language was generated with an incompatible version of the Tree-sitter framework.
inline bool fredbuf_ts_parser_set_language(tree_sitter_parser self, const TSLanguage *language)
{
    return ts_parser_set_language(self.parser, language);
}

/// Get current language about a `tree_sitter_parser` object.
///
/// - Returns: May be `NULL`.
inline const TSLanguage *fredbuf_ts_parser_get_language(tree_sitter_parser self)
{
    return ts_parser_language(self.parser);
}

static const char *fredbuf_load_utf16_string(tree_sitter_parser *parser, uint32_t byte_index, TSPoint position, uint32_t *bytes_read)
{
    if (parser->input_char) {
        free(parser);
        parser->input_char = NULL;
    }
    uint32_t index = byte_index / sizeof(CHAR_T);
    uint32_t length = (uint32_t)parser->piece_tree->length();
    if (index >= length) {
        *bytes_read = 0;
        return "";
    }
    Line line = parser->piece_tree->line_at(CharOffset { index });
    LineRange line_range = parser->piece_tree->get_line_range(line);
    uint32_t read_length = 0;
    uint32_t line_start_index = (uint32_t)line_range.first;
    uint32_t line_end_index = (uint32_t)line_range.last;
    if (line_end_index >= length) {
        read_length = 1;
    } else {
        read_length = line_end_index - index + 1;
    }
    parser->input_char = (char*)malloc((read_length + 1) * sizeof(CHAR_T));
    int loop_index = 0;
    CHAR_T *input_char = (CHAR_T*)parser->input_char;
    for(; loop_index < read_length; loop_index++) {
        CHAR_T codeUnit = parser->piece_tree->at(CharOffset { loop_index + index });
        input_char[loop_index] = codeUnit;
    }
    input_char[loop_index] = '\0';
    *bytes_read = read_length * sizeof(CHAR_T);
    return parser->input_char;
}

inline TSInput fredbuf_load_ts_input(tree_sitter_parser *parser)
{
    TSInput input = {
        parser,
        (const char *(*)(void *, uint32_t, TSPoint, uint32_t *))fredbuf_load_utf16_string,
        TSInputEncodingUTF16
    };
    return input;
}

/// Set parse cancel state
///
/// This function is thread safe.
inline void fredbuf_ts_parser_set_cancel(tree_sitter_parser *self, bool is_cancel)
{
    __atomic_store_n((volatile uint32_t*)self->cancel_flag, (is_cancel ? 1U : 0U), __ATOMIC_SEQ_CST);
}


/// Get parse cancel state
///
/// This function is thread safe.
inline bool fredbuf_ts_parser_get_cancel(tree_sitter_parser *self)
{
    return (atomic_load(self->cancel_flag) != 0);
}


/// Parsing entire document for the first time.
///
/// Time Complexity: `O(n)`.
inline TSTree *fredbuf_ts_parser_first_parse_string(tree_sitter_parser *self) {
    fredbuf_ts_parser_set_cancel(self, false);
    return ts_parser_parse(self->parser, NULL, fredbuf_load_ts_input(self));
}

/// Parsing entire document increasly by old `TSTree` object.
///
/// Time Complexity: `O(m)`, `m` is the length of modified text range.
inline TSTree *fredbuf_ts_parser_update_parse_string(tree_sitter_parser *self, const TSTree *old_tree) {
    fredbuf_ts_parser_set_cancel(self, false);
    return ts_parser_parse(self->parser, old_tree, fredbuf_load_ts_input(self));
}





//MARK: - TSPoint Convert

/// Convert a `UTF-16` code unit index at Piece Tree to `TSPoint` struct.
inline TSPoint fredbuf_convert_u16index_to_point(tree_sitter_parser *parser, size_t utf16_index)
{
    size_t piece_tree_length = (size_t)parser->piece_tree->length();
    uint16_t byte_index = sizeof(CHAR_T) * utf16_index;
    
    if (utf16_index >= piece_tree_length) { /// This situation must be consider to ASSERT false.
        Line line = parser->piece_tree->line_at(CharOffset { (size_t)parser->piece_tree->line_count() });
        LineRange line_range = parser->piece_tree->get_line_range(line);
        size_t start_u16_index = (size_t)line_range.first;
        printf("[fredbuf][AssertFailure] UTF-16 index %ld out of range.\n", utf16_index);
        assert(false);
        return {
            (uint32_t)(size_t)parser->piece_tree->line_count(),
            (uint32_t)((piece_tree_length - start_u16_index) * sizeof(CHAR_T))
        };
    }
    Line line = parser->piece_tree->line_at(CharOffset { utf16_index });
    LineRange line_range = parser->piece_tree->get_line_range(line);
    size_t start_u16_index = (size_t)line_range.first;
    uint32_t column = (uint32_t)((utf16_index - start_u16_index + 1) * sizeof(CHAR_T));
    return {
        (uint32_t)(size_t)line,
        column
    };
}

/// Convert a `UTF-16` code unit index range at Piece Tree to `TSRange` struct.
inline TSRange fredbuf_convert_u16range_to_range(tree_sitter_parser *self, size_t utf16_index_start, size_t utf16_index_end) {
    return {
        fredbuf_convert_u16index_to_point(self, utf16_index_start),
        fredbuf_convert_u16index_to_point(self, utf16_index_end),
        (uint16_t)(utf16_index_start * sizeof(CHAR_T)),
        (uint16_t)(utf16_index_end * sizeof(CHAR_T))
    };
}

/// Convert a  `TSPoint` struct to `UTF-16` code unit index.
inline size_t fredbuf_convert_point_to_index(tree_sitter_parser *self, TSPoint point) {
    size_t row = point.row;
    size_t column_u16index = point.column;
    size_t line_count = (size_t)self->piece_tree->line_count();
    if (row > line_count) {
        printf("[fredbuf][AssertFailure] line index %ld out of range: 1..%ld\n", row, line_count);
        assert(false);
    }
    LineRange line_range = self->piece_tree->get_line_range(Line{ row });
    size_t line_range_start = (size_t)line_range.first;
    size_t line_range_end = (size_t)line_range.last;
    size_t line_length = line_range_end - line_range_start;
    if ((size_t)line_range.last < (size_t)self->piece_tree->length()) {
        line_length ++;
    }
    if (column_u16index > line_length) {
        printf("[fredbuf][AssertFailure]");
        assert(false);
    }
    return (line_range_start + column_u16index - 1);
}


