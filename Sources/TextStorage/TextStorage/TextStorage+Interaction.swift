//
//  TextStorage+Interaction.swift
//
//
//  Created by 孟超 on 2024/1/18.
//

import Foundation
@_implementationOnly import PieceTree

@available(iOS 13.0, macOS 12.0, *)
extension TextStorage {
    
    /// 在指定的编码单元位置插入文本
    func insertWithoutCheck(text: NSString, at position: Int, respectComposedCharacter: Bool) -> (insertedFirstUnitIndex: Int, movedFirstUnitIndex: Int) {
        guard position < self.length else { /* directly insert */
            self.pieceTree.insertString(text as String, atOffset: position)
            return (position, position + text.length)
        }
        guard respectComposedCharacter else {
            self.pieceTree.insertString(text as String, atOffset: position)
            return (position, position + text.length)
        }
        let characterRange =  self.characterWithoutCheck(at: position).range
        self.pieceTree.insertString(text as String, atOffset: characterRange.lowerBound)
        return (characterRange.lowerBound, characterRange.lowerBound + text.length)
        
    }
    
    /// 删除指定的编码单元所对应的所有字符
    func deleteWithoutCheck(range: Range<Int>) -> Range<Int> {
        let nsRange = NSRange(range)
        let first = self.characterWithoutCheck(at: nsRange.lowerBound).range.lowerBound
        let end = self.characterWithoutCheck(at: nsRange.upperBound - 1).range.upperBound
        let length = end - first
        self.pieceTree.remove(at: first, withLength: length)
        return first..<end
    }
    
    /// 获取某个编码单元的索引对应的编码单元
    func codeUnitWithoutCheck(at position: Int) -> UInt16 {
        self.pieceTree.getCodeUnit(at: position)
    }
    
    /// 获取某个编码单元对应的字符及其对应的编码单元范围
    func characterWithoutCheck(at position: Int, composeCRLFCharacter: Bool = false) -> (character: Character, range: Range<Int>) {
        var actualRange = NSRange()
        let string = self.pieceTree.substringOfComposedCharacterSequence(at: position, withActualRange: &actualRange)
        guard composeCRLFCharacter else {
            return (Character(string), actualRange.lowerBound..<actualRange.upperBound)
        }
        if string == "\r" && position + 1 < self.length && self.codeUnitWithoutCheck(at: position + 1) == 10 { /* [CR]LF*/
            return (Character("\r\n"), position..<position + 2)
        } else if string == "\n" && position - 1 >= 0 && self.codeUnitWithoutCheck(at: position - 1) == 13 { /* CR[LF]*/
            return (Character("\r\n"), (position - 1)..<position + 1)
        } else {
            return (Character(string), actualRange.lowerBound..<actualRange.upperBound)
        }
    }
    
    /// 获取某个编码单元所在的行的所有信息
    func lineContentWithoutCheck(unitIndex position: Int) -> Line {

        let lineIndex = self.lineIndexWithoutCheck(at: position)
        var crlf_type_t: CRLF_Type_t = .init(0) /* CRFL */
        var lineRange = NSRange()
        let content = self.pieceTree.getCRFLLineContent(atLineIndex: lineIndex, withActualCRFLType: &crlf_type_t, withActualRange: &lineRange)
        let lineType = LineType.fromBridge(crlf_type_t)
        return .init(index: lineIndex, range: lineRange.lowerBound..<lineRange.upperBound, type: lineType, nsString: content as NSString)
    }
    
    /// 获取某行编号所对应的行的所有信息
    func lineContentWithoutCheck(lineIndex: Int) -> Line {
        var line_type: CRLF_Type_t = .init(0) /* LF */
        var lineRange = NSRange()
        let content = self.pieceTree.getCRFLLineContent(atLineIndex: lineIndex, withActualCRFLType: &line_type, withActualRange: &lineRange)
        let lineType = LineType.fromBridge(line_type)
        return .init(index: lineIndex, range: lineRange.lowerBound..<lineRange.upperBound, type: lineType, nsString: content as NSString)
    }
    
    /// 获取某个编码单元所在的行的编号
    func lineIndexWithoutCheck(at position: Int) -> Int {
        return self.pieceTree.getLineIndex(at: position)
    }
    
    
    /// 枚举编码单元的索引范围所在的行
    func enumerateLinesWithoutCheck(in range: Range<Int>, reverse: Bool = false, closure: (Line) -> Bool) {
        let range = NSRange(range)
        if range.length <= 0 { return }
        let firstLineIndex = self.lineIndexWithoutCheck(at: range.lowerBound)
        let endLineIndex = self.lineIndexWithoutCheck(at: range.upperBound - 1)
        loop: for i in firstLineIndex...endLineIndex {
            let index = reverse ? endLineIndex + firstLineIndex - i : i
            if closure(self.lineContentWithoutCheck(lineIndex: index)) {
                continue loop
            }
            break loop
        }
    }
}
