//
//  WebComicsAppDelegate.h
//  WebComics
//
//  Created by Paul Wagener on 14-05-10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//
#import "MainTabView.h"

@interface WebComicsAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
	IBOutlet MainTabView *tabBarController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end

