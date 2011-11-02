//
//  ComicViewer.h
//  WebComics
//
//  Created by Paul Wagener on 14-05-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comic.h"
#import "CenterUIScrollView.h"
#import "Archive.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

//Animation times
#define TITLE_FADE_TIME 0.2
#define COMIC_FADE_TIME 0.2

//Decrease to allow slower flicks to register
#define FLICK_TRESHOLD 4

//Increase to allow slower flick animation
#define MAX_FLICKANIMATION_DURATION 0.5

//The bufferspace between a comic and the next
#define COMIC_SPACING 10

//Status of the next & previous comic shown in the background
enum background_status {
	BACKGROUND_COMIC_LEFTSIDE,
	BACKGROUND_COMIC_RIGHTSIDE,
	BACKGROUND_COMIC_NONE,
	BACKGROUND_COMIC_DONTSHOW
};

//Status of other comic features that are shown in the background
enum feature_status {
	BACKGROUND_FEATURE_BOTTOMSIDE,
	BACKGROUND_FEATURE_TOPSIDE,
	BACKGROUND_FEATURE_NONE,
	BACKGROUND_FEATURE_DONTSHOW
};

enum flick_animation_status {
	NO_ANIMATION,
	ANIMATING,
	BOUNCING_BACK
};

enum flick_direction {
	FLICK_TO_LEFT,
	FLICK_TO_RIGHT,
	FLICK_TO_TOP,
	FLICK_TO_BOTTOM,
	NO_FLICK
};
@class Archive;

@interface ComicViewer : UIViewController<UIScrollViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, WebcomicSiteDelegate> {
    
@private
	//Interface elements
    IBOutlet CenterUIScrollView *mainScrollView;
	IBOutlet CenterUIScrollView *backgroundComicScrollView;
	IBOutlet CenterUIScrollView *backgroundFeatureScrollView;
	IBOutlet UILabel *titleLabel;
	IBOutlet UIToolbar *toolbar;
	IBOutlet UINavigationBar *navigationbar;
	IBOutlet UIBarButtonItem *firstButton;
	IBOutlet UIBarButtonItem *previousButton;
	IBOutlet UIBarButtonItem *archiveButton;
	IBOutlet UIBarButtonItem *nextButton;
	IBOutlet UIBarButtonItem *lastButton;
	IBOutlet UIView *archiveDownloadView;

	Archive *archiveController;
	
	//The site that we are using for the comics
	WebcomicSite *site;
	NSString *startingComicUrl;
	
	//The comics that are shown on screen
	Comic *previousComic;
	Comic *currentComic;
	Comic *nextComic;

	//Current visible comic feature (e.g. wether the comic or the alt text or the hidden comic is shown)
	enum ComicFeature currentComicFeature;
	
	//Toolbar visibility
	BOOL UIvisible;	
	
	//Backgroundviews variables
	enum background_status backgroundComicStatus;
	enum feature_status backgroundFeatureStatus;

	//Animation variables
	enum flick_animation_status flickAnimation;
	BOOL alwaysShowBackgroundOnLeft;
	BOOL alwaysShowBackgroundOnTop;	
	CGPoint outOfViewOffset;
	enum flick_direction flickStatus;
	CGFloat flickAnimationDuration;
	
	//Scrollview speed variables for determining how fast to flick the comic
	CGPoint previousContentOffset;
	CGFloat horizontalScrollSpeed;
	CGFloat verticalScrollSpeed;
}

-(id)initWithUrl:(NSString*)url: (WebcomicSite*)theSite;
- (id) initWithSite:(WebcomicSite*)site;
+(CGRect) getScreenBounds;
-(void)alertComicFeatureUpdated: (Comic*)comic: (enum ComicFeature)feature;
+(void)alertComicFeatureUpdated: (Comic*)comic: (enum ComicFeature)feature;
-(void) doFlick:(enum flick_direction) flickDirection :(int)flickSpeed;
-(void) goToComic:(NSString*)url;

- (void) goToPrevious;
- (void) goToNext;
- (void) showUI;

@end
