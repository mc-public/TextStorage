# TextStorage
![](https://img.shields.io/badge/Platform_Compatibility-iOS13.0+-blue)
![](https://img.shields.io/badge/Swift_Compatibility-5.8-red)

**TextStorage** 框架是基于 *PieceTree* 数据结构的文本存储框架，提供了文本存储类 `TextStorage`，用于为 `iOS` 平台的高性能文本编辑器提供底层文本数据结构支持。

### PieceTree 数据结构
关于此数据结构的详细阐述可以[查阅 VSCode 官方的这篇文章](https://code.visualstudio.com/blogs/2018/03/23/text-buffer-reimplementation/)，其 TypeScript 实现可以[查阅 VSCode 官方的存储库](https://github.com/microsoft/vscode-textbuffer/)。本框架使用的 PieceTree 数据结构实现是基于 C++ 的 PieceTree 实现 [**fredbuf** 框架](https://github.com/cdacamar/fredbuf) 的 UTF-16 修改版本。

### Unicode 支持
为了方便框架的使用者与苹果的 CoreText 等框架进行交互，此框架仅支持 UTF-16 编码。关于 UTF-16 编码等，可以参考 [文章: NSString 与 Unicode 的关系](https://objccn.io/issue-9-1/)，本说明文档不再赘述。

为了保持与 `NSString` 等 Foundation 字符串的兼容性，本类提供了一些简单易用的 API 以供使用者在 UTF-16 编码单元索引和实际 Unicode 字符索引之间进行转换操作。

### 换行支持
本框架支持两种换行方式：CRLF 换行方式和 LF 换行方式。
- 对于 CRLF 换行方式，我们把 `\r\n` 视作一整个换行符；
- 对于 LF 换行方式，我们把 `\n` 视作一整个换行符。

`TextStorage` 类提供了完善的 API，在您使用和行有关的 API 时，所返回的 `TextStorage.Line` 结构体中包含了当前行的实际换行方式。

### API 示例
以下为 API 使用示例。更详细的文档可以直接查看源代码注释。
```Swift
import TextStorage
let str = String(repeating: "🌍🌍✅🌍🌍🌍🌍🌍🌍🌍🌍🌍🌍HelloWorld你好世界\n", count: 5)
let storage = TextStorage.init(str)
storage.commitState()
try? storage.insert(text: "123", at: 0)
try? storage.delete(range: 0..<2)
print(storage.string)
storage.undo()
print(storage.string)
print(try! storage.lineIndex(at: 60))
```


