

@interface TextViewWithPlaceholder : UITextView  {
    NSString *placeholder;
    UIColor *placeholderColor;
}

@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;
@end
