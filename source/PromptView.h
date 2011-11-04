//
//  PromptView.h
//  WebComics
//
//  Created by Paul Wagener on 04-11-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PromptView : UIAlertView<UITextFieldDelegate, UIAlertViewDelegate> {
    UITextField *textField;
    id<UIAlertViewDelegate> realDelegate;
}

- (id)initWithPrompt:(NSString *)prompt delegate:(id)delegate cancelButtonTitle:(NSString *)cancelTitle acceptButtonTitle:(NSString *)acceptTitle;
- (NSString *)enteredText;
@end
