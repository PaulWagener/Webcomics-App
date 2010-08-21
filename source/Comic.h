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

enum ComicFeature {
	mainComicFeature,
	altTextFeature,
	hiddenComicFeature,
	newsFeature,
	pageInfo
};

@interface NSString(XMLEntities)
- (NSString *)stringByDecodingXMLEntities;
@end

@interface Comic : NSObject<UIWebViewDelegate>{
	
	
	//The site that this comic belongs to
	WebcomicSite *site;
	
	//The webpage that displays the comic
	NSString *url;
	
	NSString *title;

	//The pages that contain to the next and previous comics
	NSString *previousUrl;
	NSString *nextUrl;
	NSString *hiddencomicUrl;
	
	//Used only for markAsRead()
	NSString *comicUrl;
	BOOL markRead;
	
	//The actual comic in image-form
	UIImage *comicImage;
	UIImage *hiddencomicImage;
	
	//Connections for downloading comic-related stuff
	NSURLConnection *pageConnection;
	NSURLConnection *comicConnection;
	NSURLConnection *hiddencomicConnection;
	
	//Progress for image downloading
	UIProgressView *comicProgress;
	long long expectedComicLength;
	UIProgressView *hiddencomicProgress;
	long long expectedHiddencomicLength;
	
	
	//Views
	UIImageView *comicView;
	UIImageView *hiddenComicView;
	UILabel *altTextView;
	UIWebView *newsView;
	
	NSMutableData *pageData;
	NSMutableData *comicData;
	NSMutableData *hiddencomicData;
}


- (id) initWithUrl:(NSString*)url:(WebcomicSite*)site;
- (void) connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData;
- (void) connectionDidFinishLoading:(NSURLConnection *)theConnection;
-(UIView*) getFeature:(enum ComicFeature)index;
-(NSString*) getTitle;
-(void) markAsRead;

@property (nonatomic, retain) WebcomicSite *site;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *previousUrl;
@property (nonatomic, retain) NSString *nextUrl;
@property (nonatomic, retain) NSString *comicUrl;
@property (nonatomic, retain) NSString *hiddencomicUrl;
@property (nonatomic, retain) UIImage *comicImage;

@end
