//
//  UpdateViewController.h
//  WebComics
//
//  Created by Paul Wagener on 10-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UpdateViewController : UIViewController {
	IBOutlet UILabel *revisionLabel;
	IBOutlet UIButton *updateButton;
	IBOutlet UIActivityIndicatorView *activityView;
	IBOutlet UILabel *label;
}
+(void) doUpdateWithString:(NSString*)string;
@end
