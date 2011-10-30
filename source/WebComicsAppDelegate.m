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
	[mainTabView release];
	
	//Return to the comic last read by the user (if any)
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSString *url = [prefs objectForKey:@"lastComicRead"];
	int siteId = [prefs integerForKey:@"lastSiteRead"];
	
	if(url != nil && siteId != 0) {
		NSString *description = [[Database getDatabase] getSiteDescription:siteId];
		WebcomicSite *site = [[WebcomicSite alloc] initWithString:description];

		ComicViewer *comicViewer = [[ComicViewer alloc] initWithUrl:url :site];
		[navigationController pushViewController:comicViewer animated:NO];
		[site release];
	}
	
	[window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
}


- (void)applicationWillTerminate:(UIApplication *)application {
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}


@end

