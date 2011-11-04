//
//  PromptView.m
//  WebComics
//
//  Created by Paul Wagener on 04-11-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PromptView.h"

@implementation PromptView

- (id)initWithPrompt:(NSString *)prompt delegate:(id)delegate cancelButtonTitle:(NSString *)cancelTitle acceptButtonTitle:(NSString *)acceptTitle {
    while ([prompt sizeWithFont:[UIFont systemFontOfSize:18.0]].width > 240.0) {
        prompt = [NSString stringWithFormat:@"%@...", [prompt substringToIndex:[prompt length] - 4]];
    }
    realDelegate = delegate;
    
    CGFloat y = [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait ? 45.0 : 27.0;
    if (self = [super initWithTitle:prompt message:@"\n" delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:acceptTitle, nil]) {
        textField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, y, 260.0, 31.0)]; 
        textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.textAlignment = UITextAlignmentCenter;
        textField.returnKeyType = UIReturnKeyGo;
        textField.keyboardType = UIKeyboardTypeURL;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.delegate = self;
        
        //Pre-paste URL's
        NSString *pasteText = [[UIPasteboard generalPasteboard] string];
        if([pasteText hasPrefix:@"http"])
            textField.text = pasteText;

        [self addSubview:textField];
        
        // if not >= 4.0
        NSString *sysVersion = [[UIDevice currentDevice] systemVersion];
        if (![sysVersion compare:@"4.0" options:NSNumericSearch] == NSOrderedDescending) {
            CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, 130.0); 
            [self setTransform:translate];
        }
    }
    return self;
}

- (void)show {
    [textField becomeFirstResponder];
    [textField paste:self];
    [super show];
}

- (NSString *)enteredText {
    return textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self dismissWithClickedButtonIndex:1 animated:YES];
    return YES;
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
    textField.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleTopMargin;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [realDelegate alertView:alertView willDismissWithButtonIndex:buttonIndex];
}

@end