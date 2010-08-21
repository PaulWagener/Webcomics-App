//
//  FavoritesTableController.h
//  WebComics
//
//  Created by Paul Wagener on 21-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MainTabView.h"


@interface FavoritesTableController : UITableViewController {
	IBOutlet MainTabView *mainTabView;
	
	NSArray *favoriteSites;
	NSArray *favoriteComics;
}

@property (nonatomic, retain) NSArray *favoriteSites;
@property (nonatomic, retain) NSArray *favoriteComics;

@end
