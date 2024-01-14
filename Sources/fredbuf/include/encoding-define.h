//
//  encoding-define.h
//  
//
//  Created by 孟超 on 2024/1/13.
//


#ifndef TEXTBUF_UTF16/// We use UTF-16 encoding
#define TEXTBUF_UTF16
#endif /* TEXTBUF_UTF16 */

#ifdef TEXTBUF_UTF16
#define char_t uint16_t 
#elif defined(TEXTBUF_UTF8)
#define char_t uint8_t
#elif defined(TEXTBUF_UTF32)
#define char_t uint32_t
#endif
