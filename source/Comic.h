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
    
    NSString *title;
	
	//The actual comic in image-form
	UIImage *comicImage;
	NSString *hiddencomicUrl;
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

//The site that this comic belongs to
@property (nonatomic, strong) WebcomicSite *site;

//The webpage that displays the comic
@property (nonatomic, strong) NSString *url;

//The pages that contain to the next and previous comics
@property (nonatomic, strong) NSString *previousUrl;
@property (nonatomic, strong) NSString *nextUrl;

@end
