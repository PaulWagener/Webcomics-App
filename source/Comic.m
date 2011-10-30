//
//  Comic.m
//  WebComics
//
//  Created by Paul Wagener on 16-05-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Comic.h"
#import "WebcomicSite.h"
#import "ComicViewer.h"
#import "common.h"
#import "Database.h"

@implementation Comic

@synthesize site, url, title, comicImage, previousUrl, nextUrl, comicUrl, hiddencomicUrl;

/**
 * Gets an image of a progress indicator
 * MUST be released manually to prevent memory leak!
 */
+ (UIImageView*) getProgressIndicator {
	UIImage *p1 = [UIImage imageNamed:@"1.gif"];
	UIImage *p2 = [UIImage imageNamed:@"2.gif"];
	UIImage *p3 = [UIImage imageNamed:@"3.gif"];
	UIImage *p4 = [UIImage imageNamed:@"4.gif"];
	UIImage *p5 = [UIImage imageNamed:@"5.gif"];
	UIImage *p6 = [UIImage imageNamed:@"6.gif"];
	UIImage *p7 = [UIImage imageNamed:@"7.gif"];
	UIImage *p8 = [UIImage imageNamed:@"8.gif"];
	UIImage *p9 = [UIImage imageNamed:@"9.gif"];
	UIImage *p10 = [UIImage imageNamed:@"10.gif"];
	UIImage *p11 = [UIImage imageNamed:@"11.gif"];
	UIImage *p12 = [UIImage imageNamed:@"12.gif"];
	
	UIImageView *progressIndicator = [[UIImageView alloc] initWithImage:p1];
	
	progressIndicator.animationImages = [NSArray arrayWithObjects:p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, nil];
	progressIndicator.animationRepeatCount = 0;
	progressIndicator.animationDuration = 1;
	
	[progressIndicator startAnimating];
	
	return progressIndicator;
}

/**
 * Initializes the comic and immediately starts downloading the page that the comic is on
 */
- (id) initWithUrl:(NSString*)inUrl :(WebcomicSite*)inSite {
	self.url = inUrl;
	self.site = inSite;

	//Show progress indicators for all views
	comicView = [Comic getProgressIndicator];
	hiddenComicView = [Comic getProgressIndicator];
	
	//Start loading the page that the comic is on
	NSURLRequest *pageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
	pageConnection = [[NSURLConnection alloc] initWithRequest:pageRequest delegate:self];
	
    return self;
}


/**
 * Getter for all the different views this comic can have (including throbbers & progressbars)
 */
-(UIView*) getFeature:(enum ComicFeature)index {
	
	switch(index) {
		//Return the main comic (or a progressbar if its loading)
		case mainComicFeature:
			if(comicConnection != nil) {
				return comicProgress;
			} else {
				[comicView startAnimating];
				return comicView;
			}
			break;
		
		//Return the UILabel with the alttext
		case altTextFeature:
			return altTextView;
			break;
		
		//Returns the hidden comic (or a progressbar if its loading)
		case hiddenComicFeature:
			if(hiddencomicConnection != nil)
				return hiddencomicProgress;
			else {
				[hiddenComicView startAnimating];
				return hiddenComicView;
			}
			break;
			
		case newsFeature:
			return newsView;
			break;
	}
	return nil;
}

-(NSString*) getTitle {
	if(self.title)
		return self.title;

	if([site usesArchiveForComics]) {
		for(int i = 0; i < [site.archiveEntries count]; i++) {
			ArchiveEntry *entry = [site.archiveEntries objectAtIndex:i];
			if([entry.link isEqualToString:self.url])
				return entry.title;
		}
	}
	return nil;
}

-(void) markAsRead {
	if([self.site hasArchive])
		[[Database getDatabase] removeUnread:url];
	else {
		if(comicUrl != nil) {
			[[Database getDatabase] removeNew:comicUrl];
		} else {
			markRead = YES;
		}
		
	}
	
	//Save comic as last read
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:self.url forKey:@"lastComicRead"];
	[prefs setInteger:self.site.id forKey:@"lastSiteRead"];
	[prefs synchronize];
}


/**
 * Open all links that are clicked in HMTL views in an external safari tab.
 * This is the delegate method for UIWebView
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	}
	return YES;
}

/**
 * Catch how big the image is going to be for a correct progressbar calculation
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if(connection == comicConnection) {
		expectedComicLength = response.expectedContentLength;
	}
	
	if(connection == hiddencomicConnection) {
		expectedHiddencomicLength = response.expectedContentLength;
	}
}

/**
 * Get an incremental update of data from the connection
 * Also updates the progressbars
 */ 
- (void)connection:(NSURLConnection *)theConnection	didReceiveData:(NSData *)incrementalData
{
	//Receive page data
	if(theConnection == pageConnection) {
		if (pageData == nil)
			pageData = [[NSMutableData alloc] initWithCapacity:2048];
		
		[pageData appendData:incrementalData];
	}
	//Receive comic data
	if(theConnection == comicConnection) {
		if (comicData == nil)
			comicData = [[NSMutableData alloc] initWithCapacity:2048];

		[comicData appendData:incrementalData];
		comicProgress.progress = (CGFloat)comicData.length / expectedComicLength;
	}
	
	//Receive hidden comic data
	if(theConnection == hiddencomicConnection) {
		if (hiddencomicData == nil)
			hiddencomicData = [[NSMutableData alloc] initWithCapacity:2048];
		
		[hiddencomicData appendData:incrementalData];
		hiddencomicProgress.progress = (CGFloat)hiddencomicData.length / expectedHiddencomicLength;
	}
}

/**
 * Callback for every connection that finished downloading
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection
{
	//Load the page data into this instance
	if(theConnection == pageConnection) {
		//Load actual data
		NSString *page = [[NSString alloc] initWithData:pageData encoding:NSASCIIStringEncoding];
		
		//Extract data that is on the page
		if(self.site.previous != nil) self.previousUrl = [self.site getFullUrl: [page match:self.site.previous]];		
		if(self.site.next != nil) self.nextUrl = [self.site getFullUrl: [page match:self.site.next]];
		if(self.site.title != nil) self.title = [[page match:self.site.title] stringByDecodingXMLEntities];
		
		[ComicViewer alertComicFeatureUpdated:self :mainComicFeature];
		
		//Extract comic
		self.comicUrl = [self.site getFullUrl:[page match:self.site.comic]];
		if(markRead)
			[[Database getDatabase] removeNew:comicUrl];

		//Start loading the comic
		if(comicUrl != nil) {
			NSURLRequest *comicRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:comicUrl]];
			comicConnection = [[NSURLConnection alloc] initWithRequest:comicRequest delegate:self];
			comicProgress = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, 100, 10)];
		}
		
		//Remove progress indicator
		[comicView removeFromSuperview];
		comicView = nil;
		
		//Now that there is an active comicConnection we can show the comicProgress progress indicator
		[ComicViewer alertComicFeatureUpdated:self :mainComicFeature];		
		
		//Extract hidden comic
		if(site.hiddencomic != nil) {
			self.hiddencomicUrl = [self.site getFullUrl:[page match:self.site.hiddencomic]];
			//Hidden comic gets loaded AFTER the main comic has been loaded
		}

		//Extract alt text
		if(site.alt != nil) {
			NSString *alt = [page match:self.site.alt];
			if(alt == nil) alt = @"";
			else alt = [alt stringByDecodingXMLEntities];
			
			altTextView =  [[UILabel alloc] initWithFrame:[ComicViewer getScreenBounds]]; 
			altTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			altTextView.text = alt;
			altTextView.numberOfLines = 0;
			altTextView.backgroundColor = [UIColor clearColor];
			altTextView.textAlignment = UITextAlignmentCenter;
			[ComicViewer alertComicFeatureUpdated:self : altTextFeature];	
		}
		
		//Extract news
		if(site.news != nil) {
			NSString *newsHtml = [page match:self.site.news];
			if(newsHtml == nil) newsHtml = @"";
			
			NSString *html = [[@"<table height=\"100%\" width=\"100%\"><tr><td style=\"text-align: center; font-size: 250%;\">" stringByAppendingString:newsHtml] stringByAppendingString:@"</td></tr></table>"];
			
			newsView = [[UIWebView alloc] initWithFrame:[ComicViewer getScreenBounds]];
			newsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			newsView.exclusiveTouch = FALSE;
			newsView.multipleTouchEnabled = FALSE;
 			newsView.delegate = self;
			newsView.scalesPageToFit = YES;
			[newsView loadHTMLString:html baseURL:[NSURL URLWithString:comicUrl]];
			[ComicViewer alertComicFeatureUpdated:self :newsFeature];
		}
		
		//We are done processing the page, release all associated resources
		pageData = NULL;
		pageConnection = NULL;
	}
	
	//Comic finished loading
	if(theConnection == comicConnection) {
		//Get the image from the binary data
		comicView = [[UIImageView alloc] initWithImage: [UIImage imageWithData: comicData]];

		comicData = nil;
		comicConnection = nil;

		[ComicViewer alertComicFeatureUpdated:self :mainComicFeature];	

		//Start loading the hidden comic now that the main comic can be shown
		if(self.hiddencomicUrl != nil) {		
			NSURLRequest *hiddencomicRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.hiddencomicUrl]];
			hiddencomicConnection = [[NSURLConnection alloc] initWithRequest:hiddencomicRequest delegate:self];
			hiddencomicProgress = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, 100, 10)];
			[ComicViewer alertComicFeatureUpdated:self :hiddenComicFeature];
		}
	}

	//Hidden comic finished loading
	if(theConnection == hiddencomicConnection) {
		//Remove progress indicator
		[hiddenComicView removeFromSuperview];
		
		//Get the image from the binary data
		UIImage *imageObject = [UIImage imageWithData: hiddencomicData];
		hiddenComicView = [[UIImageView alloc] initWithImage: imageObject];
		
		//Release all connection resources
		hiddencomicData = nil;
		hiddencomicConnection = nil;
		hiddencomicProgress = nil;
		
		[ComicViewer alertComicFeatureUpdated:self :hiddenComicFeature];
	}
}
@end
