//
//  fredbuf_Bridge.h
//
//
//  Created by 孟超 on 2024/1/11.
//

#ifndef Fredbuf_Bridge_H
#define Fredbuf_Bridge_H

#include "./encoding-define.h"

#include <Foundation/Foundation.h>
/**
 在 fredbuf 框架中表示编码元素的索引的类型
 */
typedef size_t Index_t;
/**
 在 fredbuf 框架中表示编码元素的长度的类型
 */
typedef size_t Length_t;
/**
 在 fredbuf 框架中表示撤销或者重做标识符的类型
 */
typedef size_t UnRedoID_t;

/**
 在 fredbuf 框架中表示换行符类型的枚举
 */
typedef enum {
    /// LF 换行符，即 `\n` 换行符
    LF,
    /// CRLF 换行符，即 `\r\n` 换行符
    CRLF
} CRLF_Type_t;

/**
 在 fredbuf 框架中表示撤销或者重做操作结果的结构体
 */
typedef struct {
    BOOL is_success;
    UnRedoID_t id;
} UnRedoResult_t;

NS_ASSUME_NONNULL_BEGIN
@interface FredbufObjCBridge: NSObject
/**
 当前类使用的编码
 */
@property (nonatomic, readonly) NSStringEncoding usedEncoding;
/**
 当前类是否为空
 */
@property (nonatomic, readonly) Boolean empty;
/**
 当前类中所含的编码单元长度
 */
@property (nonatomic, readonly) Length_t length;
/**
 当前类中所含有的行数
 */
@property (nonatomic, readonly) Length_t lineCount;
/**
 当前类所对应的字符串
 
 时间复杂度为 `O(n)`
 */
@property (nonatomic, readonly) NSString *string;
/// 使用 `NSString` 字符串初始化当前类
- (instancetype)initWithString: (NSString*)string;
/// 初始化一个空的类
- (instancetype)init;

/// 在指定的编码单元偏移处插入文本
- (void)insertString: (nonnull NSString*)string atOffset: (Index_t)offset;
/// 移除指定的编码位置
- (void)removeAtIndex: (Index_t)index withLength: (Index_t)length;


/// 预先假设以 `LF` 换行方式获取指定指标处的行索引值
- (NSString *)getLFLineContentAtLineIndex: (size_t)lineIndex;
/// 预先假设以 `CRLF` 换行方式获取指定行号处的行内容
///
/// 第二个参数需要传入指针以供识别具体的换行方式
- (NSString *)getCRFLLineContentAtLineIndex: (size_t)lineIndex withActualCRFLType: (nonnull CRLF_Type_t*)actualType;
/// 获取指定指标处的行索引值
///
/// 无论处于何种换行模式(本编辑器只支持 `FL` 和 `CRFL` 换行模式)下，该方法都会返回正确的值。
- (Index_t)getLineIndexAtIndex: (Index_t)index;
/// 获取指定指标处的编码单元
- (char_t)getCodeUnitAtIndex: (Index_t)index;
/// 获取指定行号处的行范围
- (NSRange)getLineRangeAtLineIndex: (Index_t)lineIndex withCRFLType: (CRLF_Type_t)type;
/// 指定 `id` 的前提下执行撤销
- (UnRedoResult_t)undoWithID: (UnRedoID_t)id;
/// 指定 `id` 的前提下执行重做
- (UnRedoResult_t)redoWithID: (UnRedoID_t)id;
/// 保存当前的状态以供撤销或者重做
- (UnRedoID_t)commitState;
/// 执行快速撤销状态保存
- (void)quickCommitState;
/// 执行撤销
- (UnRedoResult_t)quickUndo;
/// 执行重做
- (UnRedoResult_t)quickRedo;
- (void)enumerateCodeUnitWithRange: (NSRange)range usingBlock: (BOOL (^)(Index_t index, char_t unit_char))block;
#ifdef TEXTBUF_UTF16
/// 获取指定指标处的字符单元对应的文字范围
- (NSRange)rangeOfComposedCharacterSequenceAtIndex: (Index_t)index;
/// 获取指定指标处的字符单元对应的文字
- (NSString *)substringOfComposedCharacterSequenceAtIndex:(Index_t)index withActualRange: (nullable NSRange *)actualRangePointer;
- (void)enumerateUnicodeScalarInRange: (NSRange)range usingBlock: (BOOL (^)(uint32_t character, NSRange range))block;
#endif
@end


NS_ASSUME_NONNULL_END


#endif /* Fredbuf_Bridge_H */
