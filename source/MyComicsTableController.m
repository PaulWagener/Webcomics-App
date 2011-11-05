#import "MyComicsTableController.h"
#import "Database.h"
#import "WebcomicSite.h"
#import "AllComicsTableController.h"
#import "TDBadgedCell.h"
#import "ComicViewer.h"

@implementation MyComicsTableController

/**
 * Update the list of comics from the database
 */
-(void) loadComicList {
	myComics = [[Database getDatabase] getMySites];
	[self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self loadComicList];
    
	self.title = @"Comics";
	
	editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
	refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
	doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
	addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];	
}

-(void) setNavigationButtons {
	if(editing) {
		mainTabView.navigationItem.leftBarButtonItem = doneButton;
		mainTabView.navigationItem.rightBarButtonItem = addButton;		
	} else {
		mainTabView.navigationItem.leftBarButtonItem = editButton;
		mainTabView.navigationItem.rightBarButtonItem = refreshButton;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[self loadComicList];
	[self setNavigationButtons];
}

#pragma mark -
#pragma mark Callbacks

/**
 * Callback for 'edit' button.
 * Puts table in editing mode
 */
-(void) edit {
	editing = true;
	[self setNavigationButtons];
	[self.tableView setEditing:YES animated:TRUE];
}

/**
 * Callback for 'done' button
 */
-(void) done {
	editing = false;
	[self setNavigationButtons];
	[self.tableView setEditing:NO animated:YES];
}

/**
 * Callback for 'add' button
 */
-(void) add {
	AllComicsTableController *allComics = [[AllComicsTableController alloc] init];
	[mainTabView.navigationController pushViewController:allComics animated:YES];
}

#pragma mark Refresh

/**
 * Callback for 'refresh' button
 */
- (void) refresh {
	if([myComics count] == 0)
		return;
	
	refreshButton.enabled = NO;
	comicsRefreshing = [myComics count];
	
	for(int row = 0; row < [myComics count]; row++) {
		TDBadgedCell *cell = (TDBadgedCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
		
		//No need to update if we already know there are new comics
		if(cell.badgeNumber == -1) {
			comicsRefreshing--;
			continue;
		}
		
		//Make the cell have an activity spinner
		cell.badgeNumber = 0;
		UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[activityView startAnimating];
		[cell setAccessoryView:activityView];
		
		//Download the information for new comics, see below method for callback action
		WebcomicSite *site = [myComics objectAtIndex:row];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [site updateUnread];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //Remove activity indicator and reload number on badge
                cell.accessoryView = nil;
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                
                //To save memory delete the comics that were downloaded
                site.archiveEntries = nil;
                
                //Enable refresh button if this was the last site to be updated
                comicsRefreshing--;
                if(comicsRefreshing == 0) {
                    refreshButton.enabled = TRUE;                    
                }
            });
        });
	}
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [myComics count];
}

/**
 * Set up the cell with the name of the comic
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	//Disabled reuse caching because it isn't handled well by the TDBadgedCell class
    static NSString *CellIdentifier = @"Cell";
    TDBadgedCell *cell = [[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	
	WebcomicSite *site = [myComics objectAtIndex:indexPath.row];

	//Display 'new' or the number of unread comics depending on the type...
	if([site hasArchive]) {
		cell.badgeNumber = [[Database getDatabase] getUnreadCount:site.id];
	} else {
		cell.badgeNumber = [[Database getDatabase] hasNew:site.id] ? -1 : 0;		
	}
	
    cell.textLabel.text = site.name;
    return cell;
}


/**
 * User clicked, go to the selected comic
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	WebcomicSite *site = [myComics objectAtIndex:indexPath.row];
	ComicViewer *viewer = [[ComicViewer alloc] initWithSite:site];
	[mainTabView.navigationController pushViewController:viewer animated:YES];
}

#pragma mark Delete comics

/**
 * Delete a row from the personal list
 */
-(void) deleteSite {
	[[Database getDatabase] deleteMySite:deleteSiteId];
	
	//Update local list & UI
	myComics = [[Database getDatabase] getMySites];
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:deleteIndexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if(editingStyle == UITableViewCellEditingStyleDelete) {
		
		//Remove site from database
		WebcomicSite *site = [myComics objectAtIndex:indexPath.row];
		
		deleteIndexPath = indexPath;
		deleteSiteId = site.id;
		
		if(site.id < 0) {
			//Show an extra confirmation before deletion
			UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure? This will delete your custom definition." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
			sheet.delegate = self;
			[sheet showInView:self.view];
		} else {
			[self deleteSite];
		}
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 0) {
		[self deleteSite];
	} else {
		//Remove the 'delete' confirmation from the cell
		UITableViewCell *aCell = [self.tableView cellForRowAtIndexPath:deleteIndexPath];
		if ( aCell.showingDeleteConfirmation ){
			aCell.editing = NO;
			aCell.editingAccessoryView = nil;
			aCell.editing = YES;			
		}
		
	}
}

#pragma mark Move comics

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	WebcomicSite *fromSite = [myComics objectAtIndex:fromIndexPath.row];
	WebcomicSite *toSite = [myComics objectAtIndex:toIndexPath.row];
	
	[[Database getDatabase] moveMySiteRow:fromSite.id :toSite.id];
	
	//Update local list
	myComics = [[Database getDatabase] getMySites];	
}

@end

