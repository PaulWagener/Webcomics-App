//
//  MainTabView.h
//  WebComics
//
//  Created by Paul Wagener on 09-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MainTabView : UIViewController<UITabBarControllerDelegate> {
	IBOutlet UITabBarController *tabController;
}

@end
