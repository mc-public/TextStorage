//
//  encoding.h
//
//
//  Created by mc-public on 2024/1/13.


#include "../include/encoding-define.h"


#ifndef TEXTBUF_ENCODING_H
#define TEXTBUF_ENCODING_H

#ifdef TEXTBUF_UTF16            /* UTF-16 */

#define     STRING_VIEW             u16string_view
#define     STRING                  u16string
#define     CHAR_T                  char16_t
#define     NS_FREDBUF_ENCODING     NSUTF16LittleEndianStringEncoding /* NOT USE BIG ENDIAN */
#define     CF_FREDBUF_ENCODING     kCFStringEncodingUTF16LE

#elif defined(TEXTBUF_UTF8)     /* UTF-8 */

#define     STRING_VIEW             string_view
#define     STRING                  string
#define     CHAR_T                  char
#define     NS_FREDBUF_ENCODING     NSUTF8StringEncoding
#define     CF_FREDBUF_ENCODING     kCFStringEncodingUTF8

#elif defined(TEXTBUF_UTF32)    /* UTF-32 */

#define     STRING_VIEW             wstring_view
#define     STRING                  wstring
#define     CHAR_T                  wchar_t
#define     NS_FREDBUF_ENCODING     NSUTF32LittleEndianStringEncoding /* NOT USE BIG ENDIAN */
#define     CF_FREDBUF_ENCODING     kCFStringEncodingUTF32LE
#endif

#endif /* TEXTBUF_ENCODING_H */
