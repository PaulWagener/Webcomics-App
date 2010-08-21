//
//  CustomSiteController.h
//  WebComics
//
//  Created by Paul Wagener on 11-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextViewWithPlaceholder.h"

@interface CustomSiteController : UIViewController<UITextViewDelegate, UIActionSheetDelegate> {
	IBOutlet TextViewWithPlaceholder *description;
	IBOutlet UITextField *fakeBorder;
	IBOutlet UIButton *deleteButton;
	IBOutlet UIButton *saveButton;
	IBOutlet UIButton *addButton;

	BOOL editMode;
	int siteId;
}

- (id)initAddSite;
- (id)initEditSite:(int)theSiteId;
@end
