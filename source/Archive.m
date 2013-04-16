#import "Archive.h"
#import "TDBadgedCell.h"
#import "Database.h"
@implementation Archive

- (id)initWithSite:(WebcomicSite*)theSite :(ComicViewer*)theComicViewer {
	self = [self initWithNibName:@"Archive" bundle:nil];
	site = theSite;
	comicViewer = theComicViewer;
	self.title = @"Archive";
	return self;
}

/**
 * Set the comic that is currently viewed
 * Given as a string that contains the link (URL) to the comic
 */
-(void)setSelectedComic:(NSString*)comic {
	for(int i = 0; i < [site.archiveEntries count]; i++) {
		ArchiveEntry *archiveEntry = [site.archiveEntries objectAtIndex:i];
		if([comic isEqualToString:archiveEntry.link]) {
			selectedComic = i;
			return;
		}
	}
}

/**
 * Make sure the table doesn't underlap the translucent navigationbar
 */
-(void)adjustTableSize {
	CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
	table.frame = CGRectMake(0, navigationBarHeight, self.view.frame.size.width, self.view.frame.size.height-navigationBarHeight);
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self adjustTableSize];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	table.dataSource = self;
	table.delegate = self;
	[self adjustTableSize];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(contextMenu)];

	//Scroll to the current comic
	[table reloadData];
	[table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:selectedComic inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

#pragma mark -
#pragma mark Context Menu

enum ArchiveActionSheetButtons {
	MarkAllAsRead,
	MarkAllAsUnread
};

-(void)contextMenu {
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
	[sheet addButtonWithTitle:@"Mark all as read"];
	[sheet addButtonWithTitle:@"Mark all as unread"];
	[sheet addButtonWithTitle:@"Cancel"];
	sheet.cancelButtonIndex = 2;
	sheet.delegate = self;
	[sheet showInView:self.view];
}

/**
 * User clicked on a button on actionsheet
 * Now mark all comics either as read or unread
 */
-(void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	Database *database = [Database getDatabase];
	switch(buttonIndex) {
		case MarkAllAsRead:
			[database removeAllUnread:site.id];
			break;
			
		case MarkAllAsUnread:
		{
			NSMutableArray *unread = [[NSMutableArray alloc] init];
			for(int i = 0; i < [site.archiveEntries count]; i++) {
				ArchiveEntry *entry = [site.archiveEntries objectAtIndex:i];
				[unread addObject:entry.link];
			}
			
			[database addUnread:site.id :unread];
			
			break;
		}
	}
	[table reloadData];
}

#pragma mark -
#pragma mark Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [site.archiveEntries count];
}


/**
 * Setup the text and 'new' badge for a specific cell
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    //Create cell
    static NSString *CellIdentifier = @"Cell";
	TDBadgedCell *cell = [[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];    
    
	//Setup cell
	ArchiveEntry *entry = [site.archiveEntries objectAtIndex:indexPath.row];
	
	Database *database = [Database getDatabase];
	if([database isUnread:entry.link])
		cell.badgeNumber = -1;
	cell.textLabel.text = entry.title;
	
    return cell;
}

/**
 * Give the current comic cell a slightly different color
 */
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.row == selectedComic)
		cell.backgroundColor = [UIColor colorWithRed:1 green:1 blue:0.7 alpha:1];
	
}


/**
 * Go to the selected comic
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//Go to the selected comic
	ArchiveEntry *archiveEntry = [site.archiveEntries objectAtIndex:indexPath.row];
	[comicViewer goToComic:archiveEntry.link];

	[self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

@end
