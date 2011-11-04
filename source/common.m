#import "common.h"
#import "RegexKitLite.h"
#import <CoreData/CoreData.h>
/**
 * Converts all xml entities to regular characters
 * Regards to Walty on stackoverflow for this function
 */
@implementation NSString(XMLEntities)
- (NSString *)stringByDecodingXMLEntities {
    NSUInteger myLength = [self length];
    NSUInteger ampIndex = [self rangeOfString:@"&" options:NSLiteralSearch].location;
	
    // Short-circuit if there are no ampersands.
    if (ampIndex == NSNotFound) {
        return self;
    }
    // Make result string with some extra capacity.
    NSMutableString *result = [NSMutableString stringWithCapacity:(myLength * 1.25)];
	
    // First iteration doesn't need to scan to & since we did that already, but for code simplicity's sake we'll do it again with the scanner.
    NSScanner *scanner = [NSScanner scannerWithString:self];
	
    [scanner setCharactersToBeSkipped:nil];
	
    NSCharacterSet *boundaryCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r;"];
	
    do {
        // Scan up to the next entity or the end of the string.
        NSString *nonEntityString;
        if ([scanner scanUpToString:@"&" intoString:&nonEntityString]) {
            [result appendString:nonEntityString];
        }
        if ([scanner isAtEnd]) {
            goto finish;
        }
        // Scan either a HTML or numeric character entity reference.
        if ([scanner scanString:@"&amp;" intoString:NULL])
            [result appendString:@"&"];
        else if ([scanner scanString:@"&apos;" intoString:NULL])
            [result appendString:@"'"];
        else if ([scanner scanString:@"&quot;" intoString:NULL])
            [result appendString:@"\""];
        else if ([scanner scanString:@"&lt;" intoString:NULL])
            [result appendString:@"<"];
        else if ([scanner scanString:@"&gt;" intoString:NULL])
            [result appendString:@">"];
        else if ([scanner scanString:@"&#" intoString:NULL]) {
            BOOL gotNumber;
            unsigned charCode;
            NSString *xForHex = @"";
			
            // Is it hex or decimal?
            if ([scanner scanString:@"x" intoString:&xForHex]) {
                gotNumber = [scanner scanHexInt:&charCode];
            }
            else {
                gotNumber = [scanner scanInt:(int*)&charCode];
            }
			
            if (gotNumber) {
                [result appendFormat:@"%C", charCode];
				
				[scanner scanString:@";" intoString:NULL];
            }
            else {
                NSString *unknownEntity = @"";
				
				[scanner scanUpToCharactersFromSet:boundaryCharacterSet intoString:&unknownEntity];
				[result appendFormat:@"&#%@%@", xForHex, unknownEntity];
				
                NSLog(@"Expected numeric character entity but got &#%@%@;", xForHex, unknownEntity);
				
            }
			
        }
        else {
			NSString *amp;
			
			[scanner scanString:@"&" intoString:&amp];      //an isolated & symbol
			[result appendString:amp];
        }
		
    }
    while (![scanner isAtEnd]);
	
finish:
    return result;
}


static char base64EncodingTable[64] = {
'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

+ (NSString *) base64StringFromData: (NSData *)data length: (int)length {
	int lentext = [data length]; 
	if (lentext < 1) return @"";
	
	char *outbuf = malloc(lentext*4/3+4); // add 4 to be sure
	
	if ( !outbuf ) return nil;
	
	const unsigned char *raw = [data bytes];
	
	int inp = 0;
	int outp = 0;
	int do_now = lentext - (lentext%3);
	
	for ( outp = 0, inp = 0; inp < do_now; inp += 3 )
	{
		outbuf[outp++] = base64EncodingTable[(raw[inp] & 0xFC) >> 2];
		outbuf[outp++] = base64EncodingTable[((raw[inp] & 0x03) << 4) | ((raw[inp+1] & 0xF0) >> 4)];
		outbuf[outp++] = base64EncodingTable[((raw[inp+1] & 0x0F) << 2) | ((raw[inp+2] & 0xC0) >> 6)];
		outbuf[outp++] = base64EncodingTable[raw[inp+2] & 0x3F];
	}
	
	if ( do_now < lentext )
	{
		unsigned char tmpbuf[2] = {0,0};
		int left = lentext%3;
		for ( int i=0; i < left; i++ )
		{
			tmpbuf[i] = raw[do_now+i];
		}
		raw = tmpbuf;
		inp = 0;
		outbuf[outp++] = base64EncodingTable[(raw[inp] & 0xFC) >> 2];
		outbuf[outp++] = base64EncodingTable[((raw[inp] & 0x03) << 4) | ((raw[inp+1] & 0xF0) >> 4)];
		if ( left == 2 ) outbuf[outp++] = base64EncodingTable[((raw[inp+1] & 0x0F) << 2) | ((raw[inp+2] & 0xC0) >> 6)];
		else outbuf[outp++] = '=';
		outbuf[outp++] = '=';

	}
	
	NSString *ret = [[NSString alloc] initWithBytes:outbuf length:outp encoding:NSASCIIStringEncoding];
	free(outbuf);
	
	return ret;
}


/**
 * Shortcut method for doing a regex search
 * Returns the first captured match (the bit that is in parentheses)
 */
-(NSString*) match:(NSString*)pattern {
	return [self stringByMatching:pattern options:(RKLDotAll) inRange:NSMakeRange(0, [self length]) capture:1 error:nil];
}

-(NSArray*) matchAll:(NSString*)pattern {
	return [self componentsMatchedByRegex:pattern options:(RKLDotAll) range:NSMakeRange(0, [self length]) capture:1 error:nil];
}
@end


@implementation NSMutableArray (Reverse)

- (void)reverse {
    NSUInteger i = 0;
    NSUInteger j = [self count] - 1;
    while (i < j) {
        [self exchangeObjectAtIndex:i
                  withObjectAtIndex:j];
		
        i++;
        j--;
    }
}

@end

