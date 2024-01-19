//
//  PieceTreeStorage.mm
//
//
//  Created by mc-public on 2024/1/11.
//
#import "./fredbuf.h"
#import "../include/PieceTreeStorage.h"
#import "./encoding.h"
#import <Foundation/Foundation.h>
#import "../tree-sitter/c-parser/c-parser.h"
#import <string>
#import <iostream>

using namespace PieceTree;

Tree* loadTreeWithString(NSString* string, NSStringEncoding encoding, CFStringEncoding cf_encoding, size_t uniChar_size) {
    
    TreeBuilder builder;
    std::STRING *new_std_string;
    CFStringRef cf_string = (__bridge CFStringRef)string;
    CFIndex length = CFStringGetLength(cf_string);
    const CHAR_T* fastCString = (CHAR_T*)CFStringGetCStringPtr(cf_string, cf_encoding);
    if (fastCString == NULL) {
        CFIndex maxSize = CFStringGetMaximumSizeForEncoding(length, cf_encoding) + 1;
        char *buffer = (char *)malloc(maxSize);
        Boolean is_success = CFStringGetCString(cf_string, buffer, maxSize, cf_encoding);
        if (is_success) {
            new_std_string = new std::STRING((CHAR_T*)buffer, length);
            free(buffer);
        } else {
            free(buffer);
            @autoreleasepool {
                const NSData *data = [string dataUsingEncoding:encoding allowLossyConversion:false];
                new_std_string = new std::STRING((CHAR_T*)data.bytes, data.length / uniChar_size); /* bytes.length returns the byte number */
            }
        }
    } else {
        new_std_string = new std::STRING(fastCString, length);
    }
    builder.accept(*new_std_string);
    delete new_std_string;
    auto tree = builder.create_alloc();
    return tree;
}


typedef struct {
    NSString * _Nonnull content;
    CRLF_Type_t type;
    NSRange line_range;
} LineContent_t;

//MARK: - The Implementation of Bridge Object

@implementation PieceTreeStorage

//MARK: - Private Property
{
    NSStringEncoding _usedEncoding;
    Tree *_pieceTree;
    UnRedoID_t _nextUsableUnRedoID ;
}

//MARK: - Private Get
/* private */- (Tree*)pieceTree {
    return _pieceTree;
}

/* private */- (UnRedoID_t)nextUsableUnRedoID {
    UnRedoID_t newID = _nextUsableUnRedoID;
    _nextUsableUnRedoID++;
    return newID;
}

- (NSStringEncoding)usedEncoding {
    return _usedEncoding;
}

- (Boolean)isEmpty {
    return [self pieceTree]->is_empty();
}

- (Index_t)length {
    return (size_t)([self pieceTree]->length());
}

- (Length_t)lineCount {
    return (size_t)([self pieceTree]->line_count());
}

- (nonnull NSString *)string {
    if ((Length_t)_pieceTree->length() <= 0) {
        return [NSString string];
    }
    std::STRING *result_std_string = new std::STRING();
    result_std_string->clear();
    result_std_string->reserve(rep(_pieceTree->length()));
    PieceTree::TreeWalker walker{ _pieceTree };
    while (not walker.exhausted()) {
        result_std_string->push_back(walker.next());
    }
    NSString *result = [self convertFromStdString: *result_std_string];
    delete result_std_string;
    return result;
}

//MARK: - Life Cycle

- (void)dealloc {
    delete _pieceTree;
}

- (nonnull instancetype)init {
    return [self initWithString:[NSString string]];
}

- (nonnull instancetype)initWithString:(nonnull NSString*)string {
    self = [super init];
    NSStringEncoding encoding = NS_FREDBUF_ENCODING;
    CFStringEncoding cf_encoding = CF_FREDBUF_ENCODING;
    if (self) {
        _nextUsableUnRedoID = 0;
        _usedEncoding = encoding;
        _pieceTree = loadTreeWithString(string, encoding, cf_encoding, sizeof(CHAR_T));
    }
    return self;
}

/* private */- (std::STRING)convertFromString: (nonnull NSString*)string {
    const NSData *data = [string dataUsingEncoding:self.usedEncoding allowLossyConversion:false];
//    const NSUInteger length = [string lengthOfBytesUsingEncoding:self.usedEncoding];
    std::STRING new_std_string = std::STRING((CHAR_T*)data.bytes, data.length / sizeof(CHAR_T)); /* bytes.length returns the byte number */
    return new_std_string;
}

/* private */- (nonnull NSString*)convertFromStdString: (std::STRING)string {
    NSData *data = [NSData dataWithBytes:string.c_str() length:string.length() * sizeof(CHAR_T)];
    NSString *result = [[NSString alloc] initWithData:data encoding:[self usedEncoding]];
    if (result) {
        return result;
    }
    return [NSString string];
}

/* private */- (nonnull NSString*)convertFromStdStringPointer: (std::STRING *)string {
    NSData *data = [NSData dataWithBytes:string->c_str() length:string->length() * sizeof(CHAR_T)];
    NSString *result = [[NSString alloc] initWithData:data encoding:[self usedEncoding]];
    if (result) {
        return result;
    }
    return [NSString string];
}

- (void)insertString: (nonnull NSString*)string atOffset: (size_t)offset {
    NSAssert(offset >= 0 && offset <= [self length], ([NSString stringWithFormat:@"Insert point index %ld out of range: 0...%ld", offset, [self length]]));
    [self pieceTree]->insert(CharOffset { offset }, [self convertFromString:string]);
}

- (void)removeAtIndex: (size_t)index withLength: (size_t)length {
    NSAssert(length >= 0, ([NSString stringWithFormat:@"Remove length %ld must be a positive number.", length]));
    NSAssert(index >= 0 && index < [self length] && index + length - 1 < [self length], ([NSString stringWithFormat:@"Remove range %ld..<%ld out of range: 0..<%ld.", index, index + length, [self length]]));
    if (length == 0) {
        return;
    }
    [self pieceTree]->remove(CharOffset { index }, Length { length });
}

- (Index_t)getLineIndexAtIndex: (Index_t)index {
    NSAssert(index >= 0 && index < [self length], ([NSString stringWithFormat:@"Code unit index %ld out of range: 0..<%ld.", index, [self length]]));
    return (Index_t)([self pieceTree]->line_at(CharOffset { index }));
}

- (char_t)getCodeUnitAtIndex: (Index_t)index {
    NSAssert((index >= 0)&&(index < [self length]), ([NSString stringWithFormat:@"Code unit index %ld out of range: 0..<%ld.", index, [self length]]));
    return (char_t)([self pieceTree]->at(CharOffset { index }));
}

- (void)enumerateCodeUnitWithRange: (NSRange)range usingBlock: (BOOL (^)(Index_t index, char_t unit_char))block  {
    NSAssert(range.location >= 0 && (range.location + range.length - 1) < [self length], ([NSString stringWithFormat:@"Code unit range %ld..<%ld out of range: 0..<%ld.", range.location, range.location + range.length, [self length]]));
    Index_t i;
    loop: for(i = 0; i < range.length; i++) {
        Index_t index = i + range.location;
        BOOL value = block(index, [self getCodeUnitAtIndex:index]);
        if (value) {
            continue;
        }
        break;
    }
}

- (nonnull NSString*)getLFLineContentAtLineIndex: (size_t)lineIndex {
    NSAssert(lineIndex >= 1 && lineIndex <= [self lineCount], ([NSString stringWithFormat:@"Line index %ld out of range: 1...%ld.", lineIndex, [self lineCount]]));
    return [self getLineContentAtLineIndex:lineIndex withCRLFType:LF_TYPE].content;
}

- (nonnull NSString*)getCRFLLineContentAtLineIndex: (size_t)lineIndex withActualCRFLType: (nonnull CRLF_Type_t*)actualType withActualRange: (nonnull NSRange*)actualRange {
    NSAssert(lineIndex >= 1 && lineIndex <= [self lineCount], ([NSString stringWithFormat:@"Line index %ld out of range: 1...%ld.", lineIndex, [self lineCount]]));
    LineContent_t lineContent = [self getLineContentAtLineIndex:lineIndex withCRLFType:CRLF_TYPE];
    *actualType = lineContent.type;
    *actualRange = lineContent.line_range;
    return lineContent.content;
}

/* private */- (LineContent_t)getLineContentAtLineIndex: (size_t)lineIndex withCRLFType: (CRLF_ENUM_t)crlf_type {
    std::STRING content_buffer;
    CRLF_Type_t actualLineType = LF;
    NSRange lineNSRange = [self getLineRangeAtLineIndex:lineIndex withCRFLType:crlf_type withActualCRFLType:&actualLineType];
    //MARK: - ???????
//    if (crlf_type == LF_TYPE && actualLineType == CRLF) {
//        actualLineType = LF;
//    }
    
    _pieceTree->get_line_content(&content_buffer, Line { lineIndex} );
    Index_t remove_length = (content_buffer.length() - lineNSRange.length);
    int loop_index = 0;
    for(loop_index = 0; loop_index < remove_length; loop_index++) {
        content_buffer.pop_back();
    }
    return  { [self convertFromStdString: content_buffer], actualLineType, lineNSRange } ;
}


/// Retrieve the code unit range for a specific line number.
- (NSRange)getLineRangeAtLineIndex: (Index_t)lineIndex withCRFLType: (CRLF_ENUM_t)type withActualCRFLType: (nullable CRLF_Type_t*)actualType /* get crlf/lf/empty , regardless with type */  {
    NSAssert(lineIndex >= 1 && lineIndex <= [self lineCount], ([NSString stringWithFormat:@"Line index %ld out of range: 1...%ld.", lineIndex, [self lineCount]]));
    LineRange lineRange = _pieceTree->get_line_range(Line { lineIndex });
    NSRange lineNSRange = { (NSUInteger)lineRange.first, (NSUInteger)lineRange.last - (NSUInteger)lineRange.first  };
    if (type == LF_TYPE) {
        if (actualType != NULL) {
            *actualType = [self getLineTypeWithLFLineRange:lineNSRange];
        }
        return lineNSRange;
    } else { /* type == CRLF_TYPE */
        CRLF_Type_t real_type = [self getLineTypeWithLFLineRange:lineNSRange];
        if (actualType != NULL) {
            *actualType = real_type;
        }
        switch (real_type) {
            case CRLF:
                return NSMakeRange(lineNSRange.location, lineNSRange.length - 1);
            case LF:
                return lineNSRange;
            case EMPTY:
                return lineNSRange;
        }
    }
}

/* private */- (CRLF_Type_t)getLineTypeWithLFLineRange: (NSRange)lineRange {
    NSAssert(lineRange.location >= 0 && lineRange.location + lineRange.length <= (Index_t)_pieceTree->length(), ([NSString stringWithFormat:@"Range index %ld..<%ld out of range: 0..<%ld.", lineRange.location, lineRange.location + lineRange.length, [self length]]));
    Index_t nextCharIndex = lineRange.location + lineRange.length;
    if (nextCharIndex >= (Index_t)_pieceTree->length()) { /* next LF-line char ? */
        return EMPTY;
    }
    if (lineRange.length <= 0) {
        return LF;
    }
    CHAR_T lineEndChar = _pieceTree->at(CharOffset { nextCharIndex - 1 });
    CHAR_T nextChar = _pieceTree->at(CharOffset { nextCharIndex });
    if (lineEndChar == '\r' && nextChar == '\n') {
        return CRLF;
    } else if (nextChar == '\n') {
        return LF;
    } else if (nextChar == '\0') {
        return EMPTY;
    } else {
        NSAssert(false, @"This situation should not be occurred, please report a issue. The project is at https://github.com/mc-public/TextStorage");
        return LF;
    }
}

- (UnRedoResult_t)undoWithID: (UnRedoID_t)id {
    auto result = [self pieceTree]->try_undo(CharOffset { 0 });
    UnRedoResult_t returnValue = { result.success, (Index_t)result.op_offset };
    return returnValue;
}

- (UnRedoResult_t)redoWithID: (UnRedoID_t)id {
    auto result = [self pieceTree]->try_redo(CharOffset { 0 });
    UnRedoResult_t returnValue = { result.success, (Index_t)result.op_offset };
    return returnValue;
}

- (UnRedoID_t)commitState {
    UnRedoID_t newID = [self nextUsableUnRedoID];
    [self pieceTree]->commit_head( CharOffset { newID } );
    return newID;
}

- (void)quickCommitState {
    [self pieceTree]->commit_head( CharOffset { 0 });
}

- (UnRedoResult_t)quickUndo {
    return [self undoWithID:0];
}

- (UnRedoResult_t)quickRedo {
    return [self redoWithID:0];
}

#ifdef TEXTBUF_UTF16
/* same with NSString */
- (NSRange)rangeOfComposedCharacterSequenceAtIndex:(Index_t)index {
    NSAssert((index >= 0)&&(index < [self length]), ([NSString stringWithFormat:@"Code unit index %ld out of range: 0..<%ld.", index, [self length]]));
    NSRange range = {0, 0};
    [self substringOfComposedCharacterSequenceAtIndex:index withActualRange:&range];
    return range;
}
/* same with NSString */
- (nonnull NSString *)substringOfComposedCharacterSequenceAtIndex:(Index_t)index withActualRange: (nullable NSRange *)actualRangePointer {
    NSAssert((index >= 0)&&(index < [self length]), ([NSString stringWithFormat:@"Code unit index %ld out of range: 0..<%ld.", index, [self length]]));
    
    Index_t line_index = [self getLineIndexAtIndex:index];
    LineContent_t line_all_content = [self getLineContentAtLineIndex:line_index withCRLFType:LF_TYPE];
    NSString *line_content = line_all_content.content;//[self getLFLineContentAtLineIndex:line_index];
    NSRange range = line_all_content.line_range;//[self getLineRangeAtLineIndex:line_index withCRFLType:LF_TYPE withActualCRFLType:NULL];
    Index_t newIndex = index - range.location;
    if (newIndex >= line_content.length) {
        *actualRangePointer = NSMakeRange(index, 1);
        CHAR_T line_break = [self getCodeUnitAtIndex:index];
        if (line_break == '\r') {
            return @"\r";
        } else if (line_break == '\n') {
            return @"\n";
        } else {
            NSAssert(false, @"This situation should not be occurred, please report a issue. The project is at https://github.com/mc-public/TextStorage");
            return @"\n";
        }
    }
    NSRange str_range = [line_content rangeOfComposedCharacterSequenceAtIndex:newIndex];
    NSRange actual_range = str_range;
    actual_range.location += range.location;
    if (actualRangePointer) {
        *actualRangePointer = actual_range;
    }
    return [line_content substringWithRange:str_range];
}

/**
 Enumerate the composed character with the smallest intersection with the specified range.
 */
- (void)enumerateComposedCharacterRange: (NSRange)range usingBlock: (BOOL (^)(uint32_t character, NSRange range))block {
    NSAssert(range.length >= 0, ([NSString stringWithFormat:@"Remove length %ld must not be less than 0.", range.length]));
    if (range.length == 0) {
        return range;
    }
    NSAssert(range.location >= 0 && (range.location + range.length - 1) < [self length], ([NSString stringWithFormat:@"Code unit range %ld..<%ld out of range: 0..<%ld.", range.location, range.location + range.length, [self length]]));
    Index_t loop_index = 0;
    Index_t step = 0;
    NSRange actualRange = NSMakeRange(0, 0);
    for (; loop_index < range.length; loop_index += step) {
        NSString *character = [self substringOfComposedCharacterSequenceAtIndex:loop_index + range.location withActualRange:&actualRange];
        BOOL needNextLoop = YES;
        if (character) {
            NSData *data = [character dataUsingEncoding:NSUTF32LittleEndianStringEncoding allowLossyConversion:NO];
            if (data.length >= 1) {
                uint32_t *value = (uint32_t*)data.bytes;
                needNextLoop = block(*value, actualRange);
            }
        }
        step = (actualRange.length + actualRange.location) - (loop_index + range.location);
        if ((step >= 1) && (needNextLoop)) {
            continue;
        }
        break;
    }
}
#endif /* TEXTBUF_UTF16 */

@end


