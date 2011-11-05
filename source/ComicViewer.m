#import "ComicViewer.h"
#import "WebcomicSite.h"
#import "Comic.h"
#import "Archive.h"
#import "common.h"
#import "Database.h"
#import "PromptView.h"

@implementation ComicViewer

#pragma mark Miscellaneous

-(id)initWithSite:(WebcomicSite*)theSite {
	self = [self initWithNibName:@"ComicViewer" bundle:nil];
	site = theSite;
	return self;
}

-(id)initWithUrl:(NSString*)url: (WebcomicSite*)theSite {
	self = [self initWithSite:theSite];	
	startingComicUrl = url;
	return self;
}

+ (UIView*) loadErrorView:(NSString*)errorMessage {
    UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"Error" owner:self options:nil] objectAtIndex:0];
    UILabel *label = (UILabel*)[view viewWithTag:1];
    label.text = errorMessage;
    return view;
}

/**
 * Set an image to a scrollview and automatically show it in its most zoomed out state.
 */
-(void) setScrollViewContent: (UIView*)view withScrollview:(CenterUIScrollView*)scrollview {
	scrollview.hidden = FALSE;
	CGFloat fitWidthZoom = (scrollview.frame.size.width / view.bounds.size.width);
	CGFloat fitHeightZoom = (scrollview.frame.size.height / view.bounds.size.height);
	scrollview.minimumZoomScale = MIN(fitWidthZoom, fitHeightZoom);
	
	if(scrollview.minimumZoomScale > 1)
		scrollview.minimumZoomScale = 1;
	
    [view layoutSubviews];
	scrollview.contentView = view;
    
	[scrollview setZoomScale:MIN(1, fitWidthZoom)];
}

- (void) displayError:(NSString*)error {
    [self setScrollViewContent:[ComicViewer loadErrorView:error] withScrollview:mainScrollView];
}

/**
 * Initialize user interface elements
 */
- (void)viewDidLoad {
	[super viewDidLoad];
	currentComicFeature = mainComicFeature;
	
	firstButton.action = @selector(goToFirst);
	previousButton.action = @selector(goToPrevious);
	archiveButton.action = @selector(openArchive);
	nextButton.action = @selector(goToNext);
	lastButton.action = @selector(goToLast);
	
	mainScrollView.maximumZoomScale = 4.0;
	mainScrollView.delegate = self;
	mainScrollView.alwaysBounceVertical = YES;
	mainScrollView.alwaysBounceHorizontal = YES;
	mainScrollView.showsHorizontalScrollIndicator = NO;
	mainScrollView.showsVerticalScrollIndicator = NO;
	
	flickStatus = NO_FLICK;
	backgroundComicStatus = BACKGROUND_COMIC_NONE;
	backgroundFeatureStatus = BACKGROUND_FEATURE_NONE;
	backgroundComicScrollView.delegate = self;
	backgroundFeatureScrollView.delegate = self;
	
	//Configure toolbars & navigationbars
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
	self.wantsFullScreenLayout = YES;
	self.title = site.name;
	self.navigationController.navigationBar.translucent = TRUE;
	self.navigationController.navigationBar.alpha = 0;
	toolbar.translucent = TRUE;
	toolbar.alpha = 0;	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(contextMenu)];
	
	titleLabel.alpha = 0;
    
    @try {
        //Test the webcomic definition for validness
        [site validate];
	} 
	@catch (NSException *theException) {
        [self displayError:theException.reason];
        return;
	} 
    
    //Download the archive and load the first comic
    if([site hasArchive]) {
        archiveDownloadView.hidden = NO;


        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @try {
                [site downloadArchive];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    archiveDownloadView.hidden = YES;
                    archiveButton.enabled = YES;
                    goToUrlButton.enabled = YES;
                    
                    if(startingComicUrl == nil)
                        [self goToComic:site.last];
                    else
                        [self goToComic:startingComicUrl];
                });
            }
            @catch (NSException *exception) {
                
                //Display the error of what malfunctioned during archive downloading
                NSString *reason = exception.reason;
                dispatch_async(dispatch_get_main_queue(), ^{
                    archiveDownloadView.hidden = YES;
                    [self displayError:reason];
                });
            }
        });
    } else {
        //Remove archive button from toolbar
        NSMutableArray *items = [toolbar.items mutableCopy];
        [items removeObject: archiveButton];
        toolbar.items = items;
        
        goToUrlButton.enabled = YES;
        
        //Or just load the first comic
        if(startingComicUrl == nil)
            [self goToComic:site.last];
        else
            [self goToComic:startingComicUrl];
    }
}

/**
 * Toggle the visibility of the statusbar, navigationbar & toolbar
 */
-(void) showUI {
	UIvisible = !UIvisible;
	
	//Fade statusbar
    [[UIApplication sharedApplication] setStatusBarHidden:!UIvisible withAnimation:UIStatusBarAnimationFade];
	
	//Fade toolbar and navigation bar
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3]; //This value is approximately the same time the statusbar takes to fade.
	
	self.navigationController.navigationBar.alpha = UIvisible ? 1 : 0;
	toolbar.alpha = UIvisible ? 1 : 0;
	
	[UIView commitAnimations];
	
	
	//Being invisible messes with the position if the navigationbar,
	//everytime it gets visible we need to set it to the correct y-offset, which is just below the statusbar
	if(UIvisible) {
		CGRect r = self.navigationController.navigationBar.frame;
		r.origin.y = 20; //Height of the statusbar, can't find a reliable method in the SDK to get this value
		self.navigationController.navigationBar.frame = r;
	}
}

/**
 * Feed back the contentView to the scrollview itself. Kind of stupid that we have to do it this way but alas, this
 * delegate method MUST be implemented for zooming to work.
 */
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
	return ((CenterUIScrollView*)scrollView).contentView;
}

#pragma mark -
#pragma mark Callbacks

/**
 * Get the size of the screen which comics can use for setting the frame of alttext and newsitems
 */
-(CGRect) getScreenBounds {
	return mainScrollView.frame;
}

/**
 * This method gets called by the Comic class whenever a new view is ready
 * Here we fade in any new comic that was just downloaded
 *
 * @param comic The comic that loaded its new feature
 * @param feature The feature of the comic that got loaded (like hiddenComic).
 */
- (void) comicFeatureUpdated: (Comic*)comic: (enum ComicFeature)feature {
    if(comic == currentComic && feature == currentComicFeature){
        
        //Show the feature in the mainScrollView
        [self setScrollViewContent:[currentComic getFeature:feature] withScrollview:mainScrollView];
        
        //Fade in the feature
        mainScrollView.alpha = 0;		
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:COMIC_FADE_TIME];
        mainScrollView.alpha = 1;
        [UIView commitAnimations];
    }
}

/**
 * If the page info of the current comic got loaded we can show the title
 * and start loading the next & previous comic
 */
- (void) comicPageDownloaded: (Comic*)comic {
	if(comic == currentComic) {
		[self downloadNextPrevious];
		
		//Fade in new title		
		titleLabel.text = [comic getTitle];
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:TITLE_FADE_TIME];
		titleLabel.alpha = 1;
		[UIView commitAnimations];
    }
}

#pragma mark -
#pragma mark Context Menu

enum ActionSheetButtons {
	OpenInSafari,
	SendInEmail,
	AddToBookmarks
};

-(void)contextMenu {
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
	[sheet addButtonWithTitle:@"Open in Safari"];
	[sheet addButtonWithTitle:@"Send in email"];
	
	if([[Database getDatabase] isBookmarked:currentComic.url])
		[sheet addButtonWithTitle:@"Remove from bookmarks"];
	else
		[sheet addButtonWithTitle:@"Add bookmark"];
	
	[sheet addButtonWithTitle:@"Cancel"];
	sheet.cancelButtonIndex = 3;
	sheet.delegate = self;
	[sheet showInView:self.view];
}


-(void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch(buttonIndex) {
		case OpenInSafari:
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:currentComic.url]];
			break;
			
		case SendInEmail:
		{
			//Convert comic into e-mail
			UIImageView *view = (UIImageView*)[currentComic getFeature:mainComicFeature];
			NSData *data = UIImagePNGRepresentation(view.image);
			NSString *base64data = [NSString base64StringFromData:data length:[data length]];
			NSString *message = [NSString stringWithFormat:@"<br /><br /><a href=\"%@\">%@</a><br /><b><img src='data:image/png;base64,%@' alt='Comic'></b>", currentComic.url, currentComic.url, base64data];
			
			//Give Composer view
			MFMailComposeViewController *h = [[MFMailComposeViewController alloc] init];
			h.mailComposeDelegate = self;
			[h setMessageBody:message isHTML:YES];
			[self presentModalViewController:h animated:YES];
			break;
		}
			
		case AddToBookmarks:
			if([[Database getDatabase] isBookmarked:currentComic.url])
				[[Database getDatabase] deleteBookmark:currentComic.url];
			else
				[[Database getDatabase] addBookmark:currentComic.site.id :[currentComic getTitle] :currentComic.url];
			break;
			
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Rotation


/**
 * Allow every screen orientation possible
 */
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

/**
 * Showing the background while rotating is just asking for trouble.
 * Show it again after the view has rotated and has the proper zoomscale
 */
-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	backgroundComicStatus = BACKGROUND_COMIC_DONTSHOW;	
	backgroundFeatureStatus = BACKGROUND_FEATURE_DONTSHOW;
	backgroundComicScrollView.hidden = YES;
	backgroundFeatureScrollView.hidden = YES;
}

/**
 * Changes the minimumZoomScale of the mainScrollview to the most zoomed oud state
 * for the comic feature that is currently in it
 */
-(void)scaleMinimumZoomToImage {
	
	CGFloat fitWidthZoom = (mainScrollView.frame.size.width / [currentComic getFeature:currentComicFeature].bounds.size.width);
	CGFloat fitHeightZoom = (mainScrollView.frame.size.height / [currentComic getFeature:currentComicFeature].bounds.size.height);
	mainScrollView.minimumZoomScale = MIN(fitWidthZoom, fitHeightZoom);
	
	if(mainScrollView.minimumZoomScale > 1)
		mainScrollView.minimumZoomScale = 1;
}

/**
 * Rotating the screen may result in the comic being TOO zoomed out and not filling up the screen
 * We use this method to fix that
 */
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	//Text that is out of view needs to be turned manually
	[previousComic getFeature:altTextFeature].frame = mainScrollView.frame;
	[currentComic getFeature:altTextFeature].frame = mainScrollView.frame;
	[nextComic getFeature:altTextFeature].frame = mainScrollView.frame;
	
	CGFloat currentZoomScale = mainScrollView.zoomScale;
	
	//Adjust minimum zoomscale to new screen dimensions
	[self scaleMinimumZoomToImage];
	
	//Check if image is 'too' zoomed oud
	if(currentZoomScale < mainScrollView.minimumZoomScale) {
		
		//Centering while the scrollview zooming is glitchy, we disable it until the zooming animation has ended
		if([currentComic getFeature:currentComicFeature].frame.size.width > [currentComic getFeature:currentComicFeature].frame.size.height)
			mainScrollView.disableHorizontalCentering = YES;
		else
			mainScrollView.disableVerticalCentering = YES;
		
		//Zoom in until image fits
		[mainScrollView setZoomScale:mainScrollView.minimumZoomScale animated:YES];
		
		//NOTE: Showing the background again is delayed until after the zooming has ended (see scrollViewDidEndZooming)
	} else {
		//No extra zooming necessary. Start showing background again.
		backgroundComicStatus = BACKGROUND_COMIC_NONE;
		backgroundFeatureStatus = BACKGROUND_FEATURE_NONE;
	}
}

/**
 * If the rotation ends with a zoom we use this method to reset those.
 */
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	
	//Code to execute after the rotation is finished
	if(mainScrollView.disableVerticalCentering || mainScrollView.disableHorizontalCentering) {
		mainScrollView.contentSize = [currentComic getFeature:currentComicFeature].frame.size;
		mainScrollView.disableVerticalCentering = NO;
		mainScrollView.disableHorizontalCentering = NO;
		
		//Allow the background to be shown again
		backgroundComicStatus = BACKGROUND_COMIC_NONE;
		backgroundFeatureStatus = BACKGROUND_FEATURE_NONE;
	}
}



#pragma mark -
#pragma mark Following Background Views

/**
 * This method gets called whenever contentOffset changes in the mainScrollView
 * We use it to correctly place the backgroundScrollView offset to get an effect like Photos.app
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if(scrollView != mainScrollView)
		return;
	
	//Save the speed at which the scrollView is moving for use in how fast we have to flick the comic
	if(previousContentOffset.x != mainScrollView.contentOffset.x || previousContentOffset.y != mainScrollView.contentOffset.y) {
		horizontalScrollSpeed = mainScrollView.contentOffset.x - previousContentOffset.x;
		verticalScrollSpeed = mainScrollView.contentOffset.y - previousContentOffset.y;
		previousContentOffset = mainScrollView.contentOffset;		
	}
	
	if(backgroundComicStatus != BACKGROUND_COMIC_DONTSHOW)
	{
		CGPoint offset = backgroundComicScrollView.contentOffset;
		
		//Show comic at the left side
		if(mainScrollView.contentOffset.x < 0 || alwaysShowBackgroundOnLeft) {
			
			if(backgroundComicStatus != BACKGROUND_COMIC_LEFTSIDE) {
				backgroundComicStatus = BACKGROUND_COMIC_LEFTSIDE;
				backgroundComicScrollView.hidden = FALSE;
				[self setScrollViewContent:[previousComic getFeature:mainComicFeature] withScrollview:backgroundComicScrollView];
			}
			
			offset.x = mainScrollView.contentOffset.x + backgroundComicScrollView.frame.size.width + COMIC_SPACING;
		}
		//Show comic at the right side
		else if(mainScrollView.contentOffset.x + mainScrollView.frame.size.width > mainScrollView.contentSize.width) {
			
			if(backgroundComicStatus != BACKGROUND_COMIC_RIGHTSIDE) {
				backgroundComicStatus = BACKGROUND_COMIC_RIGHTSIDE;
				backgroundComicScrollView.hidden = FALSE;
				[self setScrollViewContent:[nextComic getFeature:mainComicFeature] withScrollview:backgroundComicScrollView];
			}
			
			offset.x = mainScrollView.contentOffset.x - MAX(mainScrollView.contentSize.width, mainScrollView.frame.size.width) - COMIC_SPACING;
		}
		//Don't show comic
		else {
			backgroundComicScrollView.hidden = TRUE;
			backgroundComicStatus = BACKGROUND_COMIC_NONE;
		}
		backgroundComicScrollView.contentOffset = offset;
	}
	
	
	if(backgroundFeatureStatus != BACKGROUND_FEATURE_DONTSHOW)
	{
		CGPoint offset = backgroundFeatureScrollView.contentOffset;
		
		//Show extra at the top side
		if((mainScrollView.contentOffset.y < 0 || alwaysShowBackgroundOnTop) && currentComicFeature != mainComicFeature) {
			
			if(backgroundFeatureStatus != BACKGROUND_FEATURE_TOPSIDE) {
				backgroundFeatureStatus = BACKGROUND_FEATURE_TOPSIDE;
				backgroundFeatureScrollView.hidden = FALSE;
				[self setScrollViewContent:[currentComic getFeature:[site getPreviousFeature:currentComicFeature]] withScrollview:backgroundFeatureScrollView];
			}
			
			offset.y = mainScrollView.contentOffset.y + backgroundFeatureScrollView.frame.size.height + COMIC_SPACING;
		}
		//Show comic at the bottom side
		else if(mainScrollView.contentOffset.y + mainScrollView.frame.size.height >= mainScrollView.contentSize.height 
				&& ![site isLastFeature:currentComicFeature]) {
			
			if(backgroundFeatureStatus != BACKGROUND_FEATURE_BOTTOMSIDE) {
				backgroundFeatureStatus = BACKGROUND_FEATURE_BOTTOMSIDE;				
				backgroundFeatureScrollView.hidden = FALSE;
				[self setScrollViewContent:[currentComic getFeature:[site getNextFeature:currentComicFeature]] withScrollview:backgroundFeatureScrollView];
			}
			
			offset.y = mainScrollView.contentOffset.y - MAX(mainScrollView.contentSize.height, mainScrollView.frame.size.height) - COMIC_SPACING;
		}
		//Don't show comic
		else {
			backgroundFeatureScrollView.hidden = TRUE;
			backgroundFeatureStatus = BACKGROUND_FEATURE_NONE;
		}
		backgroundFeatureScrollView.contentOffset = offset;
	}	
}

#pragma mark -
#pragma mark Flicking

/**
 * Method to detect flicking to the left or to the right.
 */
-(void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate {
	enum flick_direction flickDirection = NO_FLICK;
	
	//Horizontal flick
	if(ABS(horizontalScrollSpeed) > ABS(verticalScrollSpeed) && ABS(horizontalScrollSpeed) > FLICK_TRESHOLD) {
		
		//Flick left
		if(horizontalScrollSpeed < 0 && mainScrollView.contentOffset.x < 0)
			flickDirection = FLICK_TO_LEFT;
		
		//Flick right
		if(horizontalScrollSpeed > 0 && mainScrollView.contentOffset.x + mainScrollView.frame.size.width > mainScrollView.contentSize.width)
			flickDirection = FLICK_TO_RIGHT;
		
	} else if(ABS(verticalScrollSpeed) > ABS(horizontalScrollSpeed) && ABS(verticalScrollSpeed) > FLICK_TRESHOLD) {
		//Flick up
		if(verticalScrollSpeed < 0 && mainScrollView.contentOffset.y < 0)
			flickDirection = FLICK_TO_TOP;
		
		//Flick down
		if(verticalScrollSpeed > 0 && mainScrollView.contentOffset.y + mainScrollView.frame.size.height > mainScrollView.contentSize.height)
			flickDirection = FLICK_TO_BOTTOM;
	}
	
	//Do the actual flick
	if(flickDirection != NO_FLICK)
	{
		int flickSpeed = flickDirection == FLICK_TO_LEFT || flickDirection == FLICK_TO_RIGHT ? horizontalScrollSpeed : verticalScrollSpeed;
		[self doFlick:flickDirection :flickSpeed];
	}
}

/**
 * doFlick will animate the comic away as if its been flicked by the user to a particular direction
 * If the comic can't flick in that direction (because there is no comic or comic feature in that direction) it
 * will do nothing
 *
 * @param flickDirection	Direction to flick the comic in
 * @param animationDuration Indication as to how long the flick animation should take (takes slightly longer due to bouncing)
 */
-(void) doFlick:(enum flick_direction) flickDirection :(int)flickSpeed{
	
	//Cancel flicks if there is no comic (yet) in that direction
	if(	(flickDirection == FLICK_TO_RIGHT && nextComic == nil)
	   || (flickDirection == FLICK_TO_LEFT && previousComic == nil))
		return;
	
	//Cancel flicks if there is no feature in that direction
	if( (flickDirection == FLICK_TO_TOP && currentComicFeature == mainComicFeature) 
	   || (flickDirection == FLICK_TO_BOTTOM && [site isLastFeature: currentComicFeature]))
		return;
	
	//If we're flicking to a new comic fade out the title
	if(flickDirection == FLICK_TO_LEFT || flickDirection == FLICK_TO_RIGHT) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:TITLE_FADE_TIME];
		titleLabel.alpha = 0;
		[UIView commitAnimations];
	}
	
	//Disable user input to prevent weird effects
	firstButton.enabled = FALSE;
	previousButton.enabled = FALSE;
	archiveButton.enabled = FALSE;
	nextButton.enabled = FALSE;
	lastButton.enabled = FALSE;
	mainScrollView.scrollEnabled = NO;
	
	//Start flicking animation
	//Calculate where the current view should be when the animation ends
	switch(flickDirection)
	{
		case FLICK_TO_RIGHT:
			outOfViewOffset = CGPointMake(MAX(mainScrollView.contentSize.width, mainScrollView.frame.size.width) + COMIC_SPACING, 0);
			break;
			
		case FLICK_TO_LEFT:
			outOfViewOffset = CGPointMake(0 - mainScrollView.frame.size.width - COMIC_SPACING, 0);
			break;
			
		case FLICK_TO_TOP:
			outOfViewOffset = CGPointMake(0, 0 - mainScrollView.frame.size.height - COMIC_SPACING);
			break;
			
		case FLICK_TO_BOTTOM:
			outOfViewOffset = CGPointMake(0, MAX(mainScrollView.contentSize.height, mainScrollView.frame.size.height) + COMIC_SPACING);
			break;
            
            //Should not occur
        case NO_FLICK:
            break;
	}
	
	
	//Calculate the overshootOffset, which is the same as outOfViewOffset but just a little further
	//This is used to do the first animation for the bouncy effect, later in animationDidStop we will animate it to its final position
	CGPoint overshootOffset = outOfViewOffset;
	
	switch(flickDirection) {
		case FLICK_TO_LEFT:
		case FLICK_TO_RIGHT:
			flickAnimationDuration = mainScrollView.frame.size.height/ABS(flickSpeed) / 80;
			overshootOffset.x += (FLICK_TO_RIGHT ? flickSpeed : -flickSpeed) / 2;
			alwaysShowBackgroundOnTop = mainScrollView.contentOffset.y < 0;
			break;
			
		case FLICK_TO_TOP:
		case FLICK_TO_BOTTOM:
			flickAnimationDuration = mainScrollView.frame.size.height/ABS(flickSpeed) / 80;
			overshootOffset.y += (FLICK_TO_BOTTOM ? flickSpeed : -flickSpeed) / 2;
			alwaysShowBackgroundOnLeft = mainScrollView.contentOffset.x < 0;
			break;
            
            ///Should not occur
        case NO_FLICK:
            break;
            
	}
	
	if(flickAnimationDuration > MAX_FLICKANIMATION_DURATION)
		flickAnimationDuration = MAX_FLICKANIMATION_DURATION;
	
	//Save flickDirection so we know what to do once the animation ends
	flickStatus = flickDirection;
	
	
	//First animate to a position that is slightly further then the target position to simulate the bounce effect
	flickAnimation = ANIMATING;
	[mainScrollView fixPosition:overshootOffset]; //Fixing the position is necessary as otherwise the animation will get the wrong positions
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:flickAnimationDuration];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
	[UIView setAnimationDelegate: self];
	mainScrollView.contentOffset = overshootOffset;
	[UIView commitAnimations];
	
}

/**
 * Cancels the original bouncing animation if there was a successful flick done
 * This is necessary to avoid the original animation conflicting with our own flicking animation
 */
-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
	if(flickStatus != NO_FLICK) {
		[mainScrollView setContentOffset:CGPointZero animated:NO]; //mainContentOffset was here
	}
}

/**
 * Method gets called whenever the current-comic-flicked-out-of-view animation ends that is started in scrollViewDidEndDragging.
 * We use it to make the new comic the current comic, download new comics and get rid of old comics.
 */
-(void)animationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context
{
	//Not quite there yet!
	//Bounce back form the overshoot position to the final position
	if(flickAnimation == ANIMATING) {
		flickAnimation = BOUNCING_BACK;
		
		[mainScrollView fixPosition:outOfViewOffset];
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:flickAnimationDuration/2.5];
		[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDelegate: self];
		mainScrollView.contentOffset = outOfViewOffset;
		[UIView commitAnimations];
	}
	//Flick animation has ended
	//here we do all the actual changing and loading of the comics
	else if(flickAnimation == BOUNCING_BACK) {
		flickAnimation = NO_ANIMATION;
		
		switch(flickStatus) {
			case FLICK_TO_RIGHT:
			case FLICK_TO_LEFT:
            {
				
				//Change the currentComic and all the surrounding comics
				currentComicFeature = mainComicFeature;
				
				if(flickStatus == FLICK_TO_RIGHT) {
                    [previousComic cancel];
					previousComic = currentComic;
					currentComic = nextComic;
					nextComic = nil;
					
				} else if(flickStatus == FLICK_TO_LEFT) {
					[nextComic cancel];
					nextComic = currentComic;
					currentComic = previousComic;
					previousComic = nil;
				}
                
                //Download any new comics
                [self downloadNextPrevious];
				
				//Fade in title
				NSString *title = [currentComic getTitle];
				if(title != nil) {
					titleLabel.text = title;
					[UIView beginAnimations:nil context:nil];
					[UIView setAnimationBeginsFromCurrentState:YES];
					[UIView setAnimationDuration:TITLE_FADE_TIME];
					titleLabel.alpha = 1;
					[UIView commitAnimations];
				}					
				break;
            }
				
				//Just change the showing feature
            case FLICK_TO_BOTTOM:
            case FLICK_TO_TOP:
			{
				if(flickStatus == FLICK_TO_TOP) {
					currentComicFeature = [site getPreviousFeature:currentComicFeature];
				} else if(flickStatus == FLICK_TO_BOTTOM) {
					currentComicFeature = [site getNextFeature:currentComicFeature];
				}
				
				//Disallow zooming for textbased comicfeatures
				mainScrollView.maximumZoomScale = currentComicFeature == altTextFeature || currentComicFeature == newsFeature ? 1 : 4;
				
				//Changing the frame of the news in the background (because a rotation has occured) is problematic and glitchy.
				//So we always do it at the last possible moment. No nice animation but atleast its visible.
				if(currentComicFeature == newsFeature)
					[currentComic getFeature:newsFeature].frame = mainScrollView.frame;
                    
				break;
            }
                
                //Should not occur
            case NO_FLICK:
            {
                break;
            }
				
		}
		flickStatus = NO_FLICK;
		
		
		//Delete any view out of the background
		backgroundComicScrollView.contentView = nil;
		backgroundFeatureScrollView.contentView = nil;
		backgroundComicStatus = BACKGROUND_COMIC_NONE;
		backgroundFeatureStatus = BACKGROUND_FEATURE_NONE;
		[self scrollViewDidScroll:mainScrollView];
		
		//Reenable user input
		firstButton.enabled = YES;
		previousButton.enabled = YES;
		archiveButton.enabled = YES;
		nextButton.enabled = YES;
		lastButton.enabled = YES;
		mainScrollView.scrollEnabled = YES;
		
		//Set new current comic on the mainScrollView 
		[mainScrollView unfixPosition];
		[self setScrollViewContent:[currentComic getFeature:currentComicFeature] withScrollview:mainScrollView];
		mainScrollView.contentOffset = CGPointZero;
		mainScrollView.contentSize = [currentComic getFeature:currentComicFeature].frame.size;
		alwaysShowBackgroundOnLeft = FALSE;
		alwaysShowBackgroundOnTop = FALSE;
		
		[currentComic markAsRead];
	}
}

#pragma mark -
#pragma mark Navigation

/**
 * Instantly go to a specific comic without animations or transitions
 * This deletes all previously loaded comics (previous, current & next)
 */
-(void) goToComic:(NSString*)url {
    
    //Reset everything
	mainScrollView.contentView = nil;
	backgroundComicScrollView.contentView = nil;
	backgroundFeatureScrollView.contentView = nil;
    
    [previousComic cancel];
    [nextComic cancel];
    [currentComic cancel];
	previousComic = nil;
	nextComic = nil;	
	currentComicFeature = mainComicFeature;
	

	currentComic = [[Comic alloc] initWithUrl:url :site :self];    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [currentComic download];
    });
	[currentComic markAsRead];
	
	[self setScrollViewContent:[currentComic getFeature:currentComicFeature] withScrollview:mainScrollView];
}

- (IBAction)openUrlPaster:(id)sender {
    PromptView *prompView = [[PromptView alloc] initWithPrompt:[NSString stringWithFormat:@"Comic URL %@:", site.name] delegate:self cancelButtonTitle:@"Cancel" acceptButtonTitle:@"Go"];
    [prompView show];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1) {
        PromptView *promptView = (PromptView*)alertView;
        [self goToComic:[promptView enteredText]];
    }
}

- (void) goToFirst {
	[self goToComic:site.first];
}

- (void) goToPrevious {
	//Force the background to be shown on the left side for a correct animation
	[self setScrollViewContent:[previousComic getFeature:mainComicFeature] withScrollview:backgroundComicScrollView];
	backgroundComicScrollView.contentOffset = CGPointMake(mainScrollView.frame.size.width, 0);
	
	//Simulate a flick to the left
	[self doFlick:FLICK_TO_LEFT :-10];
}

- (void) goToNext {
	[self setScrollViewContent:[nextComic getFeature:mainComicFeature] withScrollview:backgroundComicScrollView];
	backgroundComicScrollView.contentOffset = CGPointMake(-mainScrollView.frame.size.width, 0);
	
    //Simulate a flick to the right
	[self doFlick:FLICK_TO_RIGHT :10];
}

- (void) goToLast {
	[self goToComic:site.last];
}

- (void) openArchive {	
	//Archive subview
	archiveController = [[Archive alloc] initWithSite:site :self];
	[archiveController setSelectedComic:currentComic.url];
    
	[self.navigationController pushViewController:archiveController animated:YES];
}

- (void) downloadNextPrevious {
    if(previousComic == nil) {
        NSString *previousUrl = [site getPreviousUrl:currentComic];
        if(previousUrl != nil) {
            previousComic = [[Comic alloc] initWithUrl:previousUrl :site :self];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [previousComic download];
            });
        }
    }
    
    if(nextComic == nil) {
        NSString *nextUrl = [site getNextUrl:currentComic];
        if(nextUrl != nil) {
            nextComic = [[Comic alloc] initWithUrl:nextUrl :site :self];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [nextComic download];
            });
        }
    }
}

- (void)viewDidUnload {
    goToUrlButton = nil;
    [super viewDidUnload];
}
@end
