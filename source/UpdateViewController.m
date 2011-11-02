//
//  UpdateViewController.m
//  WebComics
//
//  Created by Paul Wagener on 10-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UpdateViewController.h"
#import "Database.h"

static NSString *updateUrl = @"http://webcomicsapp.googlecode.com/svn/trunk/webcomiclist.txt";

@implementation UpdateViewController

/**
 * Updates the UI texts from the preferences file
 */
-(void) updateRevisionText {
	NSString *revision = [[NSUserDefaults standardUserDefaults] stringForKey:@"listRevision"];
	if(revision == nil) revision = @"-";
	revisionLabel.text = [NSString stringWithFormat:@"Revision: %@", revision];
}
-(void) updateLastUpdated {
	NSString *lastUpdated = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastUpdated"];
	if(lastUpdated == nil) lastUpdated = @"Never";
	label.text = [NSString stringWithFormat:@"Last Updated: %@", lastUpdated];
}

/**
 * Start the backgroundthread which will update the comics
 */
-(void) startUpdateThread {
	updateButton.enabled = NO;
	activityView.hidden = NO;
	[activityView startAnimating];
	label.text = @"Downloading...";
	[self performSelectorInBackground:@selector(startUpdate) withObject:nil];
}

/**
 * Parse the contents of webcomiclist.txt into the database
 */
+(void) doUpdateWithString:(NSString*)string {
	//Update comic definitions
	NSArray *comicDefinitions = [string componentsSeparatedByString:@"\n"];
	[[Database getDatabase] updateSites:comicDefinitions];
	
	//Update revision information
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterLongStyle];
	NSString *currentDate = [formatter stringFromDate:[NSDate date]];
	
	NSString *revision = [comicDefinitions objectAtIndex:0];
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs setObject:revision forKey:@"listRevision"];
	[prefs setObject:currentDate forKey:@"lastUpdated"];
	[prefs synchronize];
}

/**
 * Background thread for updating the webcomic definitions
 */
-(void) startUpdate {
	@autoreleasepool {

		NSString* list = [NSString stringWithContentsOfURL:[NSURL URLWithString:updateUrl] encoding:NSUTF8StringEncoding error:nil];
		[UpdateViewController doUpdateWithString:list];
		
		//Update UI
		updateButton.enabled = YES;
		activityView.hidden = YES;
		[self updateRevisionText];
		[self updateLastUpdated];
	
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[updateButton addTarget:self action:@selector(startUpdateThread) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
	[self updateLastUpdated];
	[self updateRevisionText];
}



@end
