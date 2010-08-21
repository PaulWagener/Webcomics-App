
@interface NSString(XMLentities)

-(NSString*) match:(NSString*)pattern;
-(NSArray*) matchAll:(NSString*)pattern;
+ (NSString *) base64StringFromData: (NSData *)data length: (int)length;
@end

@interface NSMutableArray (Reverse)

- (void)reverse;

@end;
