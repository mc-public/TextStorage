//
//  PieceTreeStorage.h
//
//
//  Created by mc-public on 2024/1/11.
//

#ifndef PieceTreeStorage_H
#define PieceTreeStorage_H

#include "./encoding-define.h"
#include <Foundation/Foundation.h>

typedef size_t Index_t;
typedef size_t Length_t;
typedef size_t UnRedoID_t;

typedef enum {
    /// LF
    LF = 0,
    /// CRLF
    CRLF = 1,
    /// No line break
    EMPTY = 2
    
} CRLF_Type_t;


typedef enum {
    LF_TYPE = 0,
    CRLF_TYPE = 1,
} CRLF_ENUM_t;

typedef struct {
    BOOL is_success;
    UnRedoID_t id;
} UnRedoResult_t;

NS_ASSUME_NONNULL_BEGIN
@interface PieceTreeStorage: NSObject
/// Always return `UTF-16` LE encoding.
@property (nonatomic, readonly) NSStringEncoding usedEncoding;
/// Whether the number of UTF-16 code units contained in the current class is 0.
@property (nonatomic, readonly) Boolean empty;
/// The number of `UTF-16` code units contained in the current class.
@property (nonatomic, readonly) Length_t length;
/// The number of lines contained in the current class.
@property (nonatomic, readonly) Length_t lineCount;
/// The string corresponding to the current class.
@property (nonatomic, readonly) NSString *string;
/// Initiate with a `NSString` object.
- (instancetype)initWithString: (NSString*)string;
/// Initiate with a empty string.
- (instancetype)init;

/// Insert string at the specified `UTF-16` code unit index.
- (void)insertString: (nonnull NSString*)string atOffset: (Index_t)offset;
/// Remove the code unit at the specified `UTF-16` code unit index.
- (void)removeAtIndex: (Index_t)index withLength: (Index_t)length;
/// Get the string corresponding to a specific line number using the `LF` line break method.
- (NSString *)getLFLineContentAtLineIndex: (size_t)lineIndex;
/// Get the string corresponding to a specific line number using the `CRLF` line break method.
- (nonnull NSString*)getCRFLLineContentAtLineIndex: (size_t)lineIndex withActualCRFLType: (nonnull CRLF_Type_t*)actualType withActualRange: (nonnull NSRange*)actualRange;
/// Get the line number where a specific `UTF-16` code unit index is located.
- (Index_t)getLineIndexAtIndex: (Index_t)index;
/// Get the code unit at the specified `UTF-16` code unit index.
- (char_t)getCodeUnitAtIndex: (Index_t)index;
/// Get the line range corresponding to a specific line number and break line mode.
- (NSRange)getLineRangeAtLineIndex: (Index_t)lineIndex withCRFLType: (CRLF_ENUM_t)type withActualCRFLType: (nullable CRLF_Type_t*)actualType;
/// Commit current state to undo and redo stack.
- (void)quickCommitState;
/// Execute undo.
- (UnRedoResult_t)quickUndo;
/// Execute redo.
- (UnRedoResult_t)quickRedo;
/// Enumerate all `UTF-16` code units within the specified `UTF-16` code unit index range.
- (void)enumerateCodeUnitWithRange: (NSRange)range usingBlock: (BOOL (^)(Index_t index, char_t unit_char))block;
#ifdef TEXTBUF_UTF16
/// Get the composed character range corresponding to the `UTF-16` code unit at the specified index.
- (NSRange)rangeOfComposedCharacterSequenceAtIndex: (Index_t)index;
/// Get the composed character corresponding to the `UTF-16` code unit at the specified index.
- (NSString *)substringOfComposedCharacterSequenceAtIndex:(Index_t)index withActualRange: (nullable NSRange *)actualRangePointer;
/// Enumerate the composed character with the smallest intersection with the specified `UTF-16` code unit range.
- (void)enumerateComposedCharacterRange: (NSRange)range usingBlock: (BOOL (^)(uint32_t character, NSRange range))block;
#endif
@end


NS_ASSUME_NONNULL_END


#endif /* PieceTreeStorage_H */
