//  OHASBasicMarkdownParser
//
//  Created by Emory Al-Imam on 12/21/13.
//

#import "OHASBasicMarkdownParser.h"
#import "NSAttributedString+Attributes.h"

@implementation OHASBasicMarkdownParser

+(NSDictionary*)tagMappings
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange textRange = [match rangeAtIndex:2];
                if (textRange.length>0)
                {
                    NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                    [foundString setTextBold:YES range:NSMakeRange(0,textRange.length)];
                    return foundString;
                } else {
                    return nil;
                }
            }, @"(\\*{2}|_{2})(.+?)\\1", /* "**bold text**" "__bold text__" on word boundaries = xxx in bold */
            
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange textRange = [match rangeAtIndex:2];
                if (textRange.length>0)
                {
                    NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                    [foundString setTextItalics:YES range:NSMakeRange(0, foundString.length)];
                    return foundString;
                } else {
                    return nil;
                }
            }, @"(?<!\\*|_)(\\*|_)([^*|_].+?)\\1(?!\\*|_)", /* "*italic text*" "_italic text_" on word boundaries = xxx in italic */
            
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange textRange = [match rangeAtIndex:2];
                if (textRange.length>0)
                {
                    NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                    [foundString setTextIsStrikethroughed:YES];
                    return foundString;
                } else {
                    return nil;
                }
            }, @"(\\~~)(.+?)\\1", /* "~~strikethrough text~~" on word boundaries = xxx in strikethrough */
            
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange textRange = [match rangeAtIndex:2];
                if (textRange.length>0)
                {
                    NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                    [foundString setTextIsSuperscripted:YES];
                    return foundString;
                } else {
                    return nil;
                }
            }, @"\\b(.+?)\\^(.+?)\\b", /* "superscript^text" */
            
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange textRange = [match rangeAtIndex:2];
                if (textRange.length>0)
                {
                    NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                    CTFontRef font = [str fontAtIndex:textRange.location effectiveRange:NULL];
                    [foundString setFontName:@"Courier" size:CTFontGetSize(font)];
                    return foundString;
                } else {
                    return nil;
                }
            }, @"(`)(.+?)\\1", /* "`xxx`" on word boundaries = xxx in Courier font */
            
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange colorRange = [match rangeAtIndex:1];
                NSRange textRange = [match rangeAtIndex:2];
                if ((colorRange.length>0) && (textRange.length>0))
                {
                    NSString* colorName = [str attributedSubstringFromRange:colorRange].string;
                    UIColor* color = OHUIColorFromString(colorName);
                    NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                    [foundString setTextColor:color];
                    return foundString;
                } else {
                    return nil;
                }
            }, @"\\{(.+?)\\|(.+?)\\}", /* "{color|text}" = text in specified color */
            
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange textRange = [match rangeAtIndex:1];
                NSRange linkRange = [match rangeAtIndex:2];
                if ((linkRange.length>0) && (textRange.length>0))
                {
                    NSString* linkString = [str attributedSubstringFromRange:linkRange].string;
                    linkString = [linkString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSMutableAttributedString* foundString = [[str attributedSubstringFromRange:textRange] mutableCopy];
                    [foundString setLink:[NSURL URLWithString:linkString] range:NSMakeRange(0, foundString.length)];
                    return foundString;
                } else {
                    return nil;
                }
            }, @"\\b\\[(.+?)\\]\\((.+?)\\)\\b", /* "[text](link)" on word boundaries = add link to text */
            
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
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
                    [foundString setTextBold:YES range:NSMakeRange(0, textRange.length)];
                    [foundString setTextItalics:YES range:NSMakeRange(0, textRange.length)];
                    
                    return foundString;
                } else {
                    return nil;
                }
            }, @"^\\s{0,3}?&gt;(.*?)$", /* "&gt;" on newline boundaries = block quote */
            
            nil];
}

@end
