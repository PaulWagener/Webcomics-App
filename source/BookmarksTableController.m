//
//  FavoritesTableController.m
//  WebComics
//
//  Created by Paul Wagener on 21-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BookmarksTableController.h"
#import "WebcomicSite.h"
#import "Database.h"
#import "ComicViewer.h"

@implementation BookmarksTableController

@synthesize bookmarkSites, bookmarkComics;

-(void) loadBookmarks {
	self.bookmarkSites = [[Database getDatabase] getBookmarkSites];
	NSMutableArray *allFavoriteComics = [[NSMutableArray alloc] init];
	
	for(int i = 0; i < [bookmarkSites count]; i++) {
		WebcomicSite *site = [bookmarkSites objectAtIndex:i];
		NSArray *comics = [[Database getDatabase] getBookmarkedComics:site.id];
		[allFavoriteComics addObject:comics];
	}
	self.bookmarkComics = allFavoriteComics;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.title = @"Bookmarks";
}

- (void)viewWillAppear:(BOOL)animated {
	[self loadBookmarks];
	[self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [bookmarkSites count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	WebcomicSite *site = [bookmarkSites objectAtIndex:section];
	return site.name;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *comics = [self.bookmarkComics objectAtIndex:section];
	return [comics count];
}

-(NSArray*) getComic:(NSIndexPath*)indexPath {
	NSArray *comics = [bookmarkComics objectAtIndex:indexPath.section];
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
	WebcomicSite *site = [bookmarkSites objectAtIndex:indexPath.section];
	NSString *url = [[self getComic:indexPath] objectAtIndex:1];
	
	ComicViewer *viewer = [[ComicViewer alloc] initWithUrl:url :site];
	[mainTabView.navigationController pushViewController:viewer animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		BOOL lastComic = [self tableView:self.tableView numberOfRowsInSection:indexPath.section] == 1;

		// Delete the row from the data source
		NSString *url = [[self getComic:indexPath] objectAtIndex:1];
		[[Database getDatabase] deleteBookmark:url];
		[self loadBookmarks];
		
		if(lastComic)
			[tableView reloadData];
		else
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];

    } 
}



@end

