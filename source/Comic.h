//
//  Comic.h
//  WebComics
//
//  Created by Paul Wagener on 16-05-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebcomicSite.h"
#import <UIKit/UIKit.h>

@class WebcomicSite;
@protocol ComicViewerDelegate;

enum ComicFeature {
	mainComicFeature,
	altTextFeature,
	hiddenComicFeature,
	newsFeature
};

@interface NSString(XMLEntities)
- (NSString *)stringByDecodingXMLEntities;
@end

@interface Comic : NSObject<UIWebViewDelegate>{
	
@private
	
	//Used only for markAsRead()
	NSString *comicUrl;
	BOOL markRead;
    
    BOOL cancelDownload;
    
    NSString *title;

	//Views
	UIView *comicView;
	UIView *hiddencomicView;
	UIView *altView;
	__block UIView *newsView;
    
    
    id <ComicViewerDelegate> delegate;
}


- (id) initWithUrl :(NSString*)url :(WebcomicSite*)site :(id<ComicViewerDelegate>)inDelegate;
- (UIView*) getFeature :(enum ComicFeature)index;
- (NSString*) getTitle;
- (void) markAsRead;
- (void) download;
- (void) cancel;

//The site that this comic belongs to
@property (nonatomic, strong) WebcomicSite *site;

//The webpage that displays the comic
@property (nonatomic, strong) NSString *url;

//The pages that contain to the next and previous comics
@property (nonatomic, strong) NSString *previousUrl;
@property (nonatomic, strong) NSString *nextUrl;

@end

/**
 * A class that helps load data in a synchronous manner but still be able to update a UIProgressView
 */
@interface SynchronousProgressRequest : NSObject< NSURLConnectionDelegate> {
@private
    NSString *url;
    UIProgressView *progress;
    NSMutableData *data;
    long long expectedDataLength;
    NSConditionLock *lock;
    NSURLConnection *connection;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (id) initWithUrlAndProgressView:(NSString*)url :(UIProgressView*)progressview;
- (NSData*) download;
+ (NSData*) downloadData:(NSString*)url :(UIProgressView*)progressview;
@end

@protocol ComicViewerDelegate 
- (void) comicFeatureUpdated: (Comic*)comic :(enum ComicFeature)feature;
- (void) comicPageDownloaded: (Comic*)comic;
- (CGRect) getScreenBounds;
- (void) downloadNextPrevious;
@end

