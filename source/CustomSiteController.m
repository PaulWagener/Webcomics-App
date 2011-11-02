//
//  CustomSiteController.m
//  WebComics
//
//  Created by Paul Wagener on 11-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CustomSiteController.h"
#import "Database.h"
#import "common.h"

@implementation CustomSiteController




 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initAddSite {
    self = [super initWithNibName:@"CustomSite" bundle:nil];
	editMode = NO;
    
    return self;
}


- (id)initEditSite:(int)theSiteId {
	self = [super initWithNibName:@"CustomSite" bundle:nil];
	editMode = YES;
	siteId = theSiteId;
	
	return self;		
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	description.delegate = self;
	fakeBorder.borderStyle = UITextBorderStyleRoundedRect;
	description.placeholder = @"Copy paste comic description here";
	self.title = @"Custom Site";
	
	[addButton addTarget:self action:@selector(add) forControlEvents:UIControlEventTouchUpInside];
	[deleteButton addTarget:self action:@selector(delete) forControlEvents:UIControlEventTouchUpInside];
	[saveButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];	
}

-(void) viewWillAppear:(BOOL)animated {
	if(editMode) {
		NSString *siteDescription = [[Database getDatabase] getSiteDescription:siteId];
		description.text = siteDescription;
		addButton.hidden = YES;
	} else {
		saveButton.hidden = YES;
		deleteButton.hidden = YES;
	}
}

/**
 *
 */
+(BOOL) checkString:(NSString*)string {
	return [string hasPrefix:@"▄█"] && [string hasSuffix:@"█▄"];
			
}

-(void) save {
	if(![CustomSiteController checkString:description.text])
		return;
	
	[[Database getDatabase] updateSiteDescription:siteId :description.text];
	[self.navigationController popViewControllerAnimated:YES];
}

/**
 * Add a site to the database
 */
- (void) add {
	if(![CustomSiteController checkString:description.text])
		return;

	[[Database getDatabase] addCustomSite:description.text];
	[self.navigationController popViewControllerAnimated:YES];

}

/**
 * Delete a comic site
 */
- (void) delete {
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure?" delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
	sheet.delegate = self;
	[sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 0) {
		[[Database getDatabase] deleteSite:siteId];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

/**
 * Make sure that the 'Done' button doesn't enter any linebreaks
 */
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return FALSE;
    }
    return TRUE;
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

@end
