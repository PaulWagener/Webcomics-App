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
@implementation WebComicsAppDelegate

@synthesize window;
@synthesize navigationController;


#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	
	//[[NSBundle mainBundle] loadNibNamed:@"MainTabView" owner:self options:nil];
	//NSLog(@"%@", tabBarController);
	MainTabView *mainTabView = [[MainTabView alloc] initWithNibName:@"MainTabView" bundle:nil];
	[navigationController pushViewController:mainTabView animated:YES];
	[window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save the comic page the user was watching
	NSString* currentUrl = [ComicViewer getCurrentUrl];
	NSLog(currentUrl);
	[application setApplicationIconBadgeNumber:8];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}


@end

