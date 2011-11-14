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

@synthesize site, url, previousUrl, nextUrl;

/**
 * Gets an image of a progress indicator
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
	
    progressIndicator.bounds = CGRectMake(0, 0, 32, 32);
	[progressIndicator startAnimating];
	
	return progressIndicator;
}

/**
 * Initializes the comic and immediately starts downloading the page that the comic is on
 * This function blocks, a LOT
 */
- (id) initWithUrl:(NSString*)inUrl :(WebcomicSite*)inSite :(id<ComicViewerDelegate>)inDelegate {
    self = [super init];
    
	self.url = inUrl;
	self.site = inSite;
    delegate = inDelegate;
    
    return self;
}

/**
 * Do all the actual downloading and parsing.
 * Should be called in a background thread.
 * Will do callbacks when views are updated
 */
- (void) download {
    //Keep a reference to ourselve so that the object can't be released before this scope ends
    //This ensures that the @finally block is properly called before the object can be dealloced
    //Might be a bug in ARC, not sure
    Comic* test = self;
    #pragma unused(test)
    
    
    @try {
        //Show progress indicator for page loading
        dispatch_sync(dispatch_get_main_queue(), ^{
            comicView = [Comic getProgressIndicator];
            [delegate comicFeatureUpdated:self :mainComicFeature];
        });
        
        //Load comicPage
		NSString *page = [NSString stringWithContentsOfURL:[NSURL URLWithString:[self.site getFullUrl: self.url]] encoding:NSUTF8StringEncoding error:nil];
        
        if(cancelDownload)
            return;
        
        if(!page)
            @throw [NSException exceptionWithName:nil reason:[NSString stringWithFormat:@"Could not load page content from %s", self.url.UTF8String] userInfo:nil];
            
		//Extract data that is on the page
		if(self.site.previous != nil) self.previousUrl = [self.site getFullUrl: [page match:self.site.previous]];
		if(self.site.next != nil) self.nextUrl = [self.site getFullUrl: [page match:self.site.next]];
		if(self.site.title != nil) title = [[page match:self.site.title] stringByDecodingXMLEntities];
		comicUrl = [self.site getFullUrl:[page match:self.site.comic]];
        
        if(!comicUrl)
            @throw [NSException exceptionWithName:nil reason:@"Could not match comic pattern on source" userInfo:nil];
        
        //Show alt text
		if(site.alt != nil) {
			NSString *alt = [page match:self.site.alt];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if(alt == nil) {
                    altView = [ComicViewer loadErrorView:@"Could not find alt text in page source"];
                } else {
                    NSString *altText = [alt stringByDecodingXMLEntities];
                    
                    UILabel *altLabel =  [[UILabel alloc] initWithFrame:delegate.getScreenBounds]; 
                    altLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    altLabel.text = altText;
                    altLabel.numberOfLines = 0;
                    altLabel.backgroundColor = [UIColor clearColor];
                    altLabel.textAlignment = UITextAlignmentCenter;
                    altView = altLabel;
                }
                [delegate comicFeatureUpdated:self : altTextFeature];
            });
		}
		
		//Extract news
		if(site.news != nil) {
			NSString *newsHtml = [page match:self.site.news];
            
            if(cancelDownload)
                return;
            
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if(newsHtml == nil) {
                    newsView = [ComicViewer loadErrorView:@"Could not find news in page source"];
                } else {
                    
                    NSString *html = [[@"<table height=\"100%\" width=\"100%\"><tr><td style=\"text-align: center; font-size: 250%;\">" stringByAppendingString:newsHtml] stringByAppendingString:@"</td></tr></table>"];
                    
                    __block UIWebView *newsWebView = [[UIWebView alloc] initWithFrame:delegate.getScreenBounds];
                    newsWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    newsWebView.exclusiveTouch = FALSE;
                    newsWebView.multipleTouchEnabled = FALSE;
                    newsWebView.delegate = self;
                    newsWebView.scalesPageToFit = YES;
                    [newsWebView loadHTMLString:html baseURL:[NSURL URLWithString:comicUrl]];
                    newsView = newsWebView;
                }
                [delegate comicFeatureUpdated:self :newsFeature];
            });
		}
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [delegate comicPageDownloaded: self];
        });
        
        //Show the comic downloading progressbar
        dispatch_sync(dispatch_get_main_queue(), ^{
            UIProgressView *progress = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, 100, 10)];
            
            comicView = progress;
            [delegate comicFeatureUpdated:self :mainComicFeature];
        });
        
        //Download the comic
        NSData *comicData = [SynchronousProgressRequest downloadData:comicUrl :(UIProgressView*)comicView];
        
        if(cancelDownload)
            return;            
        
        //Display the comic
        dispatch_sync(dispatch_get_main_queue(), ^{
            comicView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:comicData]];
            [delegate comicFeatureUpdated:self :mainComicFeature];
        });        
        comicData = nil;

		//Extract hidden comic
        @try {
            
            if(site.hiddencomic != nil) {
                NSString *pageWithHiddenComic = page;
        
                //Download seperate page that contains url to hidden comic 
                if(site.hiddencomiclink) {
                    NSString *hiddencomicPageUrl = [site getFullUrl: [page match:site.hiddencomiclink]];
                    
                    if(!hiddencomicPageUrl)
                        @throw [NSException exceptionWithName:nil reason:@"Could not find link to page with hidden comic in page source" userInfo:nil];
                    
                    pageWithHiddenComic = [NSString stringWithContentsOfURL:[NSURL URLWithString:hiddencomicPageUrl] encoding:NSASCIIStringEncoding error:nil];

                    if(cancelDownload)
                        return;
                    
                    if(!pageWithHiddenComic)
                        @throw [NSException exceptionWithName:nil reason:@"Could not download page with hidden comic image" userInfo:nil];
                }
                
                //Find hidden comic link
                NSString *hiddencomicUrl = [site getFullUrl:[pageWithHiddenComic match:site.hiddencomic]];
              
                if(!hiddencomicUrl)
                    @throw [NSException exceptionWithName:nil reason:@"Could not find link to hidden comic image" userInfo:nil];
                
                //Show the hiddencomic downloading progressbar
                dispatch_sync(dispatch_get_main_queue(), ^{
                    UIProgressView *progress = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, 100, 10)];
                    
                    hiddencomicView = progress;
                    [delegate comicFeatureUpdated:self :hiddenComicFeature];
                });
              
                //Download the hidden comic
                NSData *hiddencomicData = [SynchronousProgressRequest downloadData:hiddencomicUrl :(UIProgressView*)hiddencomicView];
                
                if(cancelDownload)
                    return;
                
                //Display the hidden comic
                dispatch_sync(dispatch_get_main_queue(), ^{
                    hiddencomicView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:hiddencomicData]];
                    [delegate comicFeatureUpdated:self :hiddenComicFeature];
                });
            }
        }
        @catch (NSException *exception) {
            NSString *reason = exception.reason;
            dispatch_sync(dispatch_get_main_queue(), ^{
                hiddencomicView = [ComicViewer loadErrorView:reason];
                [delegate comicFeatureUpdated:self :hiddenComicFeature];
            });
        }
    }
    @catch (NSException *exception) {
        //Display error as the comic view
        NSString *reason = exception.reason;
        dispatch_sync(dispatch_get_main_queue(), ^{
            comicView = [ComicViewer loadErrorView:reason];
            [delegate comicFeatureUpdated:self :mainComicFeature];
        });
    }
    @finally {
        //If the download was cancelled there is a large chance that the thread itself is the last remaining
        //owner of this object. Since releasing UI stuff on a secondary thread is a mortal sin punishable
        //by crashing we ensure that these are released on the main thread
        if(cancelDownload) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                comicView = nil;
                altView = nil;
                hiddencomicView = nil;
                newsView = nil;
            });
        }
    }
}

-(void) cancel {
    cancelDownload = YES;
}


/**
 * Getter for all the different views this comic can have (including throbbers & progressbars)
 */
-(UIView*) getFeature:(enum ComicFeature)index {
	
	switch(index) {
		//Return the main comic (or a progressbar if its loading)
		case mainComicFeature:
			return comicView;
			break;
		
		//Return the UILabel with the alttext
		case altTextFeature:
			return altView;
			break;
		
		//Returns the hidden comic (or a progressbar if its loading)
		case hiddenComicFeature:
			return hiddencomicView;
			break;
			
		case newsFeature:
			return newsView;
			break;
	}
	return nil;
}

-(NSString*) getTitle {
	if(title)
		return title;

	if([site hasArchive]) {
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
@end

@implementation SynchronousProgressRequest

- (id) initWithUrlAndProgressView:(NSString *)fileurl :(UIProgressView *)progressview {
    self = [super init];
    url = fileurl;
    progress = progressview;
    lock = [[NSConditionLock alloc] initWithCondition:0];
    data = [[NSMutableData alloc] initWithCapacity:2048];
    return self;
}

- (NSData*) download {
    //Start the download
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    });

    //Wait for download
    [lock lockWhenCondition:1];
    [lock unlock];          

    return data;
}

+ (NSData*) downloadData:(NSString *)url :(UIProgressView *)progressview {
    SynchronousProgressRequest *request = [[SynchronousProgressRequest alloc] initWithUrlAndProgressView:url :progressview];
    return [request download];
}

/**
 * Catch how big the file is going to be for a correct progressbar calculation
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    expectedDataLength = response.expectedContentLength;
}

/**
 * Get an incremental update of data from the connection
 * Also updates the progressbars
 */ 
- (void)connection:(NSURLConnection *)theConnection	didReceiveData:(NSData *)incrementalData
{
    [data appendData:incrementalData];
    
    //Update progress bar
    dispatch_async(dispatch_get_main_queue(), ^{
        progress.progress = (CGFloat)data.length / expectedDataLength;
    });
}

/**
 * Data downloading is finished, resume thread again
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection
{
    [lock lock];
    [lock unlockWithCondition:1];
}

@end
