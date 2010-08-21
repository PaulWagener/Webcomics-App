//
//  MyComicsTableController.h
//  WebComics
//
//  Created by Paul Wagener on 10-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainTabView.h"
#import "WebcomicSite.h"

@interface MyComicsTableController : UITableViewController<UIActionSheetDelegate, WebcomicSiteDelegate> {
	NSArray *myComics;
	IBOutlet MainTabView *mainTabView;
	
	BOOL editing;
	
	//Buttons on navigationbar
	UIBarButtonItem *editButton;
	UIBarButtonItem *refreshButton;
	
	//Buttons for edit mode
	UIBarButtonItem *doneButton;
	UIBarButtonItem *addButton;

	//Temporary variables to store which site is going to be deleted
	//While the user is looking at the UIActionSheet
	NSIndexPath *deleteIndexPath;
	int deleteSiteId;
	
	//Amount of comics/tablecells that are doing the twirling refreshing state
	//Used for re-enabling the refresh button if it hits zero
	int comicsRefreshing;

}

@end
