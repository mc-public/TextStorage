//
//  fredbuf+objc.m
//  
//
//  Created by 孟超 on 2024/1/11.
//
#import "./fredbuf.h"
#import "./include/fredbuf_Bridge.h"
#import "encoding.h"
#import <Foundation/Foundation.h>
#import <string>
#import <iostream>

using namespace PieceTree;


/// 加载 fredbuf 的 piece-tree
Tree* loadTreeWithString(NSString* string, NSStringEncoding encoding, size_t uniChar_size) {
    TreeBuilder builder;
    const NSData *data = [string dataUsingEncoding:encoding allowLossyConversion:false];
    const NSUInteger length = [string lengthOfBytesUsingEncoding:encoding];
    std::STRING *new_std_string = new std::STRING((CHAR_T*)data.bytes, data.length / uniChar_size); /* bytes.length returns the byte number */
    builder.accept(*new_std_string);
    delete new_std_string;
    auto tree = builder.create_alloc();
    return tree;
}


typedef struct {
    NSString * _Nonnull content;
    CRLF_Type_t type;
} LineContent_t;

//MARK: - The Implementation of Bridge Object

@implementation FredbufObjCBridge

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
    constexpr auto start = CharOffset{ 0 };
    PieceTree::TreeWalker walker{ _pieceTree, start };
    std::STRING buf;
    while (not walker.exhausted()) {
        buf.push_back(walker.next());
    }
    return [self convertFromStdString:buf];
}

//MARK: - Life Cycle

- (void)dealloc {
    delete [self pieceTree];
}

- (nonnull instancetype)init {
    return [self initWithString:[NSString string]];
}

- (nonnull instancetype)initWithString:(nonnull NSString*)string {
    self = [super init];
    NSStringEncoding encoding = NS_FREDBUF_ENCODING;
    if (self) {
        _nextUsableUnRedoID = 0;
        _usedEncoding = encoding;
        _pieceTree = loadTreeWithString(string, encoding, sizeof(CHAR_T));
    }
    return self;
}

/* private */- (std::STRING)convertFromString: (nonnull NSString*)string {
    const NSData *data = [string dataUsingEncoding:self.usedEncoding allowLossyConversion:false];
    const NSUInteger length = [string lengthOfBytesUsingEncoding:self.usedEncoding];
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
    return [self getLineContentAtLineIndex:lineIndex withUsingCRFL:false].content;
}

- (nonnull NSString*)getCRFLLineContentAtLineIndex: (size_t)lineIndex withActualCRFLType: (nonnull CRLF_Type_t*)actualType {
    NSAssert(lineIndex >= 1 && lineIndex <= [self lineCount], ([NSString stringWithFormat:@"Line index %ld out of range: 1...%ld.", lineIndex, [self lineCount]]));
    LineContent_t lineContent = [self getLineContentAtLineIndex:lineIndex withUsingCRFL:true];
    *(actualType) = lineContent.type;
    return lineContent.content;
}

/* private */- (LineContent_t)getLineContentAtLineIndex: (size_t)lineIndex withUsingCRFL: (Boolean)usingCRFL {
    std::STRING content_buffer;
    if (usingCRFL) {
        IncompleteCRLF isIncompleteCRLF = [self pieceTree]->get_line_content_crlf(&content_buffer, Line { lineIndex });
        /*返回NO表示`\n`(LF), YES 表示`\r\n`(CRLF)*/
        NSString *result = [self convertFromStdString: content_buffer];
        CRLF_Type_t type = (CRLF_Type_t)isIncompleteCRLF;
        
        return { result, type };
    } else {
        [self pieceTree]->get_line_content(&content_buffer, Line { lineIndex });
        NSString *result = [self convertFromStdString: content_buffer];
        CRLF_Type_t type = LF;
        return { result, type };
    }
}

/**
 获取某个行号对应的字符单元范围
 
 此方法越界时会触发断言
 */
- (NSRange)getLineRangeAtLineIndex: (Index_t)lineIndex withCRFLType: (CRLF_Type_t)type  {
    NSAssert(lineIndex >= 1 && lineIndex <= [self lineCount], ([NSString stringWithFormat:@"Line index %ld out of range: 1...%ld.", lineIndex, [self lineCount]]));
    LineRange range;
    if (type) { /* CRLF */
        range = [self pieceTree]->get_line_range_crlf(Line { lineIndex });
    } else { /* LF */
        range = [self pieceTree]->get_line_range(Line { lineIndex });
    }
    NSRange nsRange = { (NSUInteger)range.first, (NSUInteger)range.last - (NSUInteger)range.first  };
    return nsRange;
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
/**
 获取某个 `UTF-16` 编码单元的索引对应的字符的编码单元范围
 
 此方法越界时会触发断言
 */
- (NSRange)rangeOfComposedCharacterSequenceAtIndex:(Index_t)index {
    NSAssert((index >= 0)&&(index < [self length]), ([NSString stringWithFormat:@"Code unit index %ld out of range: 0..<%ld.", index, [self length]]));
    Index_t line_index = [self getLineIndexAtIndex:index];
    NSString *line_content = [self getLFLineContentAtLineIndex:line_index];
    NSRange range = [self getLineRangeAtLineIndex:line_index withCRFLType:LF];
    Index_t newIndex = index - range.location;
    return [line_content rangeOfComposedCharacterSequenceAtIndex:index];
}


/**
 获取某个 `UTF-16` 编码单元的索引所对应的字符
 
 
 此方法越界时会触发断言
 */
- (nonnull NSString *)substringOfComposedCharacterSequenceAtIndex:(Index_t)index withActualRange: (nullable NSRange *)actualRangePointer {
    NSAssert((index >= 0)&&(index < [self length]), ([NSString stringWithFormat:@"Code unit index %ld out of range: 0..<%ld.", index, [self length]]));
    Index_t line_index = [self getLineIndexAtIndex:index];
    NSString *line_content = [self getLFLineContentAtLineIndex:line_index];
    NSRange range = [self getLineRangeAtLineIndex:line_index withCRFLType:LF];
    Index_t newIndex = index - range.location;
    
    NSRange str_range = [line_content rangeOfComposedCharacterSequenceAtIndex:index];
    if (actualRangePointer) {
        *actualRangePointer = str_range;
    }
    return [line_content substringWithRange:str_range];
}

/**
 枚举和指定范围有最小交集的 Unicode 标量
 
 返回最小覆盖所有对应的 Unicode 标量的范围
 
 此方法越界时会触发断言
 */
- (void)enumerateUnicodeScalarInRange: (NSRange)range usingBlock: (BOOL (^)(uint32_t character, NSRange range))block {
    NSAssert(range.length >= 0, ([NSString stringWithFormat:@"Remove length %ld must not be less than 0.", range.length]));
    if (range.length == 0) {
        return range;
    }
    NSAssert(range.location >= 0 && (range.location + range.length - 1) < [self length], ([NSString stringWithFormat:@"Code unit range %ld..<%ld out of range: 0..<%ld.", range.location, range.location + range.length, [self length]]));
    Index_t loop_index = 0;
    Index_t step = 0;
    NSRange actualRange = NSMakeRange(0, 0);
    for (; loop_index < range.length; loop_index += step) {
        printf("%lu\n", loop_index + range.location);
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


#endif

@end


