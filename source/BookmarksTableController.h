//
//  FavoritesTableController.h
//  WebComics
//
//  Created by Paul Wagener on 21-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MainTabView.h"


@interface BookmarksTableController : UITableViewController {
	IBOutlet MainTabView *mainTabView;
	
	NSArray *bookmarkSites;
	NSArray *bookmarkComics;
}

@property (nonatomic, strong) NSArray *bookmarkSites;
@property (nonatomic, strong) NSArray *bookmarkComics;

@end
