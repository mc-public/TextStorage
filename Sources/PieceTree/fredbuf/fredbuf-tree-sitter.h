//
//  fredbuf-tree-sitter.h
//  
//
//  Created by mc-public on 2024/1/18.
//

#ifndef fredbuf_tree_sitter_h
#define fredbuf_tree_sitter_h
#import <stdio.h>
#import "../tree-sitter/include/tree_sitter/api.h"
#import "../fredbuf/fredbuf.h"

using namespace PieceTree;

typedef struct {
    /// `TSParser` object
    ///
    /// **Don't** directly operate this pointer. Use API functions to handle cancel state.
    TSParser *parser;
    /// `Piece Tree` object
    ///
    /// The lifecycle must be longer than `TSParser`. **Don't** directly operate this pointer. Use API functions to handle cancel state.
    PieceTree::Tree *piece_tree;
    /// `TSInput` closure cache
    ///
    /// **Don't** directly operate this pointer. Use API functions to handle cancel state.
    char *input_char;
    /// Cancel parse flag
    ///
    /// **Don't** directly operate this pointer. Use API functions to handle cancel state.
    const size_t *cancel_flag;
    /// Time out for parsing
    ///
    /// **Don't** directly operate this pointer. Use API functions to handle cancel state.
    ///
    
} tree_sitter_parser;


/// Initialize a `tree_sitter_parser` object.
inline tree_sitter_parser *fredbuf_ts_parser_init(Tree *piece_tree);
/// Delete a `tree_sitter_parser` object and free memory(except `Tree` object).
inline void fredbuf_ts_parser_free(tree_sitter_parser *self);

/// Set the parsing language for a `TSParser` object.
///
/// - Parameter self: A pointer points to a `TSParser` object.
/// - Parameter language: A pointer points to a `TSLanguage` object.
///
/// - Returns: A boolean value indicating whether or not the language was successfully assigned. `False` means there was a version mismatch, the language was generated with an incompatible version of the Tree-sitter framework.
inline bool fredbuf_ts_parser_set_language(tree_sitter_parser self, const TSLanguage *language);
/// Get current language about a `tree_sitter_parser` object.
///
/// - Returns: May be `NULL`.
inline const TSLanguage *fredbuf_ts_parser_get_language(tree_sitter_parser self);
/// Set parse cancel state
///
/// This function is thread safe.
inline void fredbuf_ts_parser_set_cancel(tree_sitter_parser *self, bool is_cancel);
/// Get parse cancel state
///
/// This function is thread safe.
inline bool fredbuf_ts_parser_get_cancel(tree_sitter_parser *self);
/// Parsing entire document for the first time.
///
/// Time Complexity: `O(n)`.
inline TSTree *fredbuf_ts_parser_first_parse_string(tree_sitter_parser *self);
/// Parsing entire document increasly by old `TSTree` object.
///
/// Time Complexity: `O(m)`, `m` is the length of modified text range.
inline TSTree *fredbuf_ts_parser_update_parse_string(tree_sitter_parser *self, const TSTree *old_tree);
/// Convert a `UTF-16` code unit index at Piece Tree to `TSPoint` struct.
inline TSPoint fredbuf_convert_u16index_to_point(tree_sitter_parser *parser, size_t utf16_index);
/// Convert a `UTF-16` code unit index range at Piece Tree to `TSRange` struct.
inline TSRange fredbuf_convert_u16range_to_range(tree_sitter_parser *self, size_t utf16_index_start, size_t utf16_index_end);
/// Convert a  `TSPoint` struct to `UTF-16` code unit index.
inline size_t fredbuf_convert_point_to_index(tree_sitter_parser *self, TSPoint point);
#endif /* fredbuf_tree_sitter_h */
