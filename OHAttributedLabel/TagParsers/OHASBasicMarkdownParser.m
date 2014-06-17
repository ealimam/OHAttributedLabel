//  OHASBasicMarkdownParser
//
//  Created by Emory Al-Imam on 12/21/13.
//

#import "OHASBasicMarkdownParser.h"
#import "NSAttributedString+Attributes.h"

@implementation OHASBasicMarkdownParser

+(NSDictionary*)tagMappings
{
    return @{
             // Bold: /* "**bold text**" "__bold text__" on word boundaries = xxx in bold */
             @"(\\*{2}|_{2})(.+?)\\1":
             ^NSAttributedString* (NSAttributedString* str, NSTextCheckingResult* match)
             {
                 NSRange textRange = [match rangeAtIndex:2];
                 if (textRange.length > 0)
                 {
                     NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                     [foundString setTextBold:YES range:NSMakeRange(0, textRange.length)];
                     return foundString;
                 } else {
                     return nil;
                 }
             },
             // Italic: /* "*italic text*" "_italic text_" on word boundaries = xxx in italic */
             @"(?<!\\*|_)(\\*|_)([^*|_].+?)\\1(?!\\*|_)":
             ^NSAttributedString* (NSAttributedString* str, NSTextCheckingResult* match)
             {
                 NSRange textRange = [match rangeAtIndex:2];
                 if (textRange.length > 0)
                 {
                     NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                     [foundString setTextItalics:YES range:NSMakeRange(0, foundString.length)];
                     return foundString;
                 } else {
                     return nil;
                 }
             },
             // Bold and Italic: /* "***bold and italic text***" "__bold italic text__" on word boundaries = xxx in bold and italics */
             @"(\\*{3}|_{3})(.+?)\\1":
                 ^NSAttributedString* (NSAttributedString* str, NSTextCheckingResult* match)
             {
                 NSRange textRange = [match rangeAtIndex:2];
                 if (textRange.length > 0)
                 {
                     NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                     [foundString setTextBold:YES range:NSMakeRange(0, textRange.length)];
                     [foundString setTextItalics:YES range:NSMakeRange(0, textRange.length)];
                     return foundString;
                 } else {
                     return nil;
                 }
             },
             // Strikethrough: /* "~~strikethrough text~~" on word boundaries = xxx in strikethrough */
             @"(\\~~)(.+?)\\1":
             ^NSAttributedString* (NSAttributedString* str, NSTextCheckingResult* match)
             {
                 NSRange textRange = [match rangeAtIndex:2];
                 if (textRange.length > 0)
                 {
                     NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                     [foundString setTextIsStrikethroughed:YES];
                     return foundString;
                 } else {
                     return nil;
                 }
             },
             // Superscript: /* "superscript^text" */
             @"\\b(.+?)\\^(.+?)\\b":
             ^NSAttributedString* (NSAttributedString* str, NSTextCheckingResult* match)
             {
                 NSRange textRange = [match rangeAtIndex:2];
                 if (textRange.length > 0)
                 {
                     NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                     [foundString setTextIsSuperscripted:YES];
                     return foundString;
                 } else {
                     return nil;
                 }
             },
             // Code syntax: /* "`xxx`" on word boundaries = xxx in Courier font */
             @"(`)(.+?)\\1":
             ^NSAttributedString* (NSAttributedString* str, NSTextCheckingResult* match)
             {
                 NSRange textRange = [match rangeAtIndex:2];
                 if (textRange.length > 0)
                 {
                     NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                     CTFontRef font = [str fontAtIndex:textRange.location effectiveRange:NULL];
                     [foundString setFontName:@"Courier" size:CTFontGetSize(font)];
                     return foundString;
                 } else {
                     return nil;
                 }
             },
             // Colorize: /* "{color|text}" = text in specified color */
             @"\\{(.+?)\\|(.+?)\\}":
             ^NSAttributedString* (NSAttributedString* str, NSTextCheckingResult* match)
             {
                 NSRange colorRange = [match rangeAtIndex:1];
                 NSRange textRange = [match rangeAtIndex:2];
                 if ((colorRange.length > 0) && (textRange.length > 0))
                 {
                     NSString* colorName = [str attributedSubstringFromRange:colorRange].string;
                     UIColor* color = OHUIColorFromString(colorName);
                     NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                     [foundString setTextColor:color];
                     return foundString;
                 } else {
                     return nil;
                 }
             },
             // Link: /* "[text](link)" on word boundaries = add link to text */
             @"\\b\\[(.+?)\\]\\s*\\((.+?)\\)\\b":
             ^NSAttributedString* (NSAttributedString* str, NSTextCheckingResult* match)
             {
                 NSRange textRange = [match rangeAtIndex:1];
                 NSRange linkRange = [match rangeAtIndex:2];
                 if ((linkRange.length > 0) && (textRange.length > 0))
                 {
                     NSString* linkString = [str attributedSubstringFromRange:linkRange].string;
                     linkString = [linkString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                     NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                     
                     // Add link
                     [foundString setLink:[NSURL URLWithString:linkString] range:NSMakeRange(0, foundString.length)];
                     
                     // Set font to medium weight, same size
                     CTFontRef currentFont = [str fontAtIndex:textRange.location effectiveRange:NULL];
                     CGFloat currentFontSize = CTFontGetSize(currentFont);
                     [foundString setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:currentFontSize]];
                     
                     return foundString;
                 } else {
                     return nil;
                 }
             },
             // Block Quote: /* ">" on newline boundaries = block quote */
             @"^\\s{0,3}?>(.*?)$":
             ^NSAttributedString* (NSAttributedString* str, NSTextCheckingResult* match)
             {
                 NSRange textRange = [match rangeAtIndex:1];
                 if (textRange.length > 0)
                 {
                     // blockquote paragraph styling
                     NSMutableParagraphStyle* blockquoteParagraphStyle = [NSMutableParagraphStyle new];
                     blockquoteParagraphStyle.headIndent = 16.0;
                     blockquoteParagraphStyle.tailIndent = -16.0;
                     blockquoteParagraphStyle.firstLineHeadIndent = 16.0;
                     blockquoteParagraphStyle.paragraphSpacing = 5.0;
                     blockquoteParagraphStyle.paragraphSpacingBefore = 5.0;
                     
                     NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                     [foundString addAttribute:NSParagraphStyleAttributeName value:blockquoteParagraphStyle range:NSMakeRange(0, foundString.length)];
                     [foundString setTextItalics:YES range:NSMakeRange(0, textRange.length)];
                     
                     return foundString;
                 } else {
                     return nil;
                 }
             },
             // Reddit /r/ and /u/ links: /* "/r/xxx" or "/u/xxx" on word boundaries */
             @"\\b(/(r|u)/(.+?))\\b":
             ^NSAttributedString* (NSAttributedString* str, NSTextCheckingResult* match)
             {
                 return nil;

                 /* TODO: Temporarily disabled */
//                 NSRange subredditOrUserLinkRange = [match rangeAtIndex:1];
//                 
//                 if (subredditOrUserLinkRange.length > 0) {
//                     NSString* subredditOrUserLink = [str attributedSubstringFromRange:subredditOrUserLinkRange].string;
//                     subredditOrUserLink = [subredditOrUserLink stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//                     
//                     NSURL *subredditURL = [NSURL URLWithString:subredditOrUserLink];
//                     
//                     NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:subredditOrUserLinkRange] mutableCopy];
//                     
//                     // Detect if this match is part of a larger URL. If so, return nil.
//                     NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink
//                                                                                    error:nil];
//                     NSArray *matches = [linkDetector matchesInString:str.string
//                                                              options:0
//                                                                range:NSMakeRange(0, str.length)];
//                     // Go through URLs detected
//                     for (NSTextCheckingResult *result in matches) {
//                         // Find if URL detected contains the match (e.g. /r/sample)
//                         NSRange foundRange = [result.URL.absoluteString rangeOfString:foundString.string];
//                         
//                         if (foundRange.location != NSNotFound) { // if found...
//                             if (subredditOrUserLinkRange.location > result.range.location) { // ...see if match starts after detected URL...
//                                 if (subredditOrUserLinkRange.length < result.range.length) { // if so, see if match is shorter than detected URL
//                                     // If so, match is a substring of a detected URL, so do not modify this match and just return as-is.
////                                     NSLog(@"result: %@ contains foundString: %@", result.URL.absoluteString, foundString.string);
//                                     return nil;
//                                 }
//                             }
//                         }
//                     }
//                     
//                     [foundString setTextBold:YES range:NSMakeRange(0, foundString.length)];
//                     [foundString setLink:subredditURL range:NSMakeRange(0, foundString.length)];
//                     
//                     return foundString;
//                 } else {
//                     return nil;
//                 }
             }
        };
}

@end
