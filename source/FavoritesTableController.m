//
//  FavoritesTableController.m
//  WebComics
//
//  Created by Paul Wagener on 21-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FavoritesTableController.h"
#import "WebcomicSite.h"
#import "Database.h"
#import "ComicViewer.h"

@implementation FavoritesTableController

@synthesize favoriteSites, favoriteComics;
/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

-(void) loadFavorites {
	self.favoriteSites = [[Database getDatabase] getFavoriteSites];
	NSMutableArray *allFavoriteComics = [[NSMutableArray alloc] init];
	
	for(int i = 0; i < [favoriteSites count]; i++) {
		WebcomicSite *site = [favoriteSites objectAtIndex:i];
		NSArray *comics = [[Database getDatabase] getFavoriteComics:site.id];
		[allFavoriteComics addObject:comics];
	}
	self.favoriteComics = allFavoriteComics;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.title = @"Favorites";
}

- (void)viewWillAppear:(BOOL)animated {
	[self loadFavorites];
	[self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [favoriteSites count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	WebcomicSite *site = [favoriteSites objectAtIndex:section];
	return site.name;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *comics = [self.favoriteComics objectAtIndex:section];
	return [comics count];
}

-(NSArray*) getComic:(NSIndexPath*)indexPath {
	NSArray *comics = [favoriteComics objectAtIndex:indexPath.section];
	return [comics objectAtIndex:indexPath.row];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	NSString *title = [[self getComic:indexPath] objectAtIndex:0];
	
    cell.textLabel.text = title;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	WebcomicSite *site = [favoriteSites objectAtIndex:indexPath.section];
	NSString *url = [[self getComic:indexPath] objectAtIndex:1];
	
	ComicViewer *viewer = [[ComicViewer alloc] initWithUrl:url :site];
	[mainTabView.navigationController pushViewController:viewer animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		BOOL lastComic = [self tableView:self.tableView numberOfRowsInSection:indexPath.section] == 1;

		// Delete the row from the data source
		NSString *url = [[self getComic:indexPath] objectAtIndex:1];
		[[Database getDatabase] deleteFavorite:url];
		[self loadFavorites];
		
		if(lastComic)
			[tableView reloadData];
		else
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];

    } 
}



@end

