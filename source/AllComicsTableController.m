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
	[self.navigationController pushViewController:[[CustomSiteController alloc] initAddSite] animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	allComics = [[Database getDatabase] getSites];
	myComics = [[Database getDatabase] getMySites];
	customComics = [[Database getDatabase] getCustomSites];
	[self.tableView reloadData];
}


// Override to allow only portrait orientation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark Table view methods

//Two sections: One for custom sites, and one for predefined sites
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
	
    //Cells shouldn't go blue when user taps them
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

/**
 * Check or uncheck a site and propagate that in the database
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //Can't check custom sites, the fact that they exist implies that the user wants to see them
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

//Let the user customize a custom site
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	WebcomicSite *site = [customComics objectAtIndex:indexPath.row];
	
	[self.navigationController pushViewController:[[CustomSiteController alloc] initEditSite:site.id] animated:YES];
}



@end

