//
//  WebComicsAppDelegate.m
//  WebComics
//
//  Created by Paul Wagener on 14-05-10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "WebComicsAppDelegate.h"
#import "ComicViewer.h"
#import "MainTabView.h"
#import "Database.h"
@implementation WebComicsAppDelegate

@synthesize window;
@synthesize navigationController;


#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	//Load the main view
	MainTabView *mainTabView = [[MainTabView alloc] initWithNibName:@"MainTabView" bundle:nil];
	[navigationController pushViewController:mainTabView animated:NO];

	[window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
}


- (void)applicationWillTerminate:(UIApplication *)application {
}


#pragma mark -
#pragma mark Memory management



@end

