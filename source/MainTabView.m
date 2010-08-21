//
//  MainTabView.m
//  WebComics
//
//  Created by Paul Wagener on 09-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MainTabView.h"


@implementation MainTabView

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Add tab interface. Whole thing is defined within the .xib
	tabController.view.frame = self.view.frame;
	tabController.delegate = self;
	[self.view addSubview:tabController.view];
}

/**
 * If a viewController is going to be visible give it a chance to configure the navigation bar
 */
-(void) setupViewController:(UIViewController*)viewController {
	self.title = viewController.title;
	self.navigationItem.leftBarButtonItem = nil;
	self.navigationItem.rightBarButtonItem = nil;
	
	//Subviewcontrollers are supposed to configure buttons & titles in their viewWillAppear
	[viewController viewWillAppear:NO];
}

BOOL alreadyLoaded;

- (void) viewWillAppear:(BOOL)animated {
	self.navigationController.navigationBar.translucent = NO;

	//Configure the navigation bar for the first time only
	if(!alreadyLoaded) {
		alreadyLoaded = TRUE;
		[self setupViewController:[tabController.viewControllers objectAtIndex:0]];
	} else {
		[tabController.selectedViewController viewWillAppear:NO];
	}
}

//Configure the navigation bar for subsequent tab changes
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	[self setupViewController:viewController];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
