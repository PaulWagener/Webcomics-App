//
//  AllComicsController.m
//  WebComics
//
//  Created by Paul Wagener on 09-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AllComicsTableController.h"
#import "Database.h"
#import "WebcomicSite.h"
#import "CustomSiteController.h"

@implementation AllComicsTableController


- (id)init {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
	self.title = @"Comic list";
}

/**
 * User press on the + sign to add his own comic definitions
 */
- (void) add {
	CustomSiteController *customSite = [[CustomSiteController alloc] initAddSite];
	[self.navigationController pushViewController:customSite animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	allComics = [[Database getDatabase] getSites];
	myComics = [[Database getDatabase] getMySites];
	customComics = [[Database getDatabase] getCustomSites];
	[self.tableView reloadData];
}


/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0)
		return [customComics count];
	else
		return [allComics count];
}

/**
 * Check if a site is selected by the user in his personal list
 */
- (BOOL) siteIsAlreadyPicked:(WebcomicSite*)site {
	for(int i = 0; i < [myComics count]; i++) {
		WebcomicSite *mysite = [myComics objectAtIndex:i];
		if(site.id == mysite.id) {
			return YES;
		}
	}
	return NO;
}

/**
 * Get the contents of a cell
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
	if(indexPath.section == 0) {
		//Custom sites
		WebcomicSite *site = [customComics objectAtIndex:indexPath.row];
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		cell.textLabel.text = site.name;
	} else {
		
		//Regular sites
		WebcomicSite *site = [allComics objectAtIndex:indexPath.row];
		cell.textLabel.text = site.name;
		cell.accessoryType = [self siteIsAlreadyPicked:site] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	}
	
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

/**
 * Check or uncheck a site and propagate that in the database
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 0)
		return;
	
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	WebcomicSite *site = [allComics objectAtIndex:indexPath.row];	
	
	if([self siteIsAlreadyPicked:site]) {
		//Remove site from personal list
		[[Database getDatabase] deleteMySite:site.id];
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else {
		//Add site to personal list
		[[Database getDatabase] addMySite:site.id];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	
	//Update the local list of sites
	myComics = [[Database getDatabase] getMySites];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	WebcomicSite *site = [customComics objectAtIndex:indexPath.row];
	
	CustomSiteController *customController = [[CustomSiteController alloc] initEditSite:site.id];
	[self.navigationController pushViewController:customController animated:YES];
}



@end

