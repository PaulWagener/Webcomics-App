//
//  WebcomicSite.h
//  WebComics
//
//  Created by Paul Wagener on 16-05-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Comic.h"

@class Comic;
enum ComicFeature;

enum archive_order {
	RECENTTOP,
	RECENTBOTTOM
};

@interface ArchiveEntry : NSObject {
	NSString *link;
	NSString *title;
};
@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) NSString *title;
@end

@class WebcomicSite;

@protocol WebcomicSiteDelegate <NSObject>
@optional
- (void)archiveDownloaded:(WebcomicSite*)site;
- (void)unreadUpdated:(WebcomicSite*)site;
@end

@interface WebcomicSite : NSObject {
	int id;
	NSString *name;
	
	//URL to prepend to all found urls
	NSString *base;
	
	//URLS to first and last comic
	NSString *first;
	NSString *last;
	
	//Finding next & previous comic
	NSString *previous;
	NSString *next;
	
	
	//Stuff to find on a comic page
	NSString *title;
	NSString *comic;
	NSString *hiddencomic;
	NSString *alt;
	NSString *news;
	
	//Archive stuffs
	NSString *archive;
	NSString *archivepart;
	NSString *archivelink;
	NSString *archivetitle;
	enum archive_order archiveorder;
	
	NSURLConnection *archiveConnection;
	NSMutableData *archiveData;
	NSMutableArray *archiveEntries;
	long long expectedArchiveLength;
	
	id<WebcomicSiteDelegate> __unsafe_unretained delegate;
}

-(id) initWithString:(NSString*)string;
- (NSString*) getFullUrl:(NSString*)partialUrl;
-(NSString*) getPreviousUrl:(Comic*)aComic;
-(NSString*) getNextUrl:(Comic*)aComic;
-(BOOL) hasArchive;
-(BOOL)usesArchiveForComics;
-(void) updateUnread;
-(void)downloadArchive;
-(bool) isLastFeature: (enum ComicFeature)feature;
-(enum ComicFeature) getPreviousFeature:(enum ComicFeature)feature;
-(enum ComicFeature) getNextFeature:(enum ComicFeature)feature;

	
@property int id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *base;
@property (nonatomic, strong) NSString *last;
@property (nonatomic, strong) NSString *first;
@property (nonatomic, strong) NSString *previous;
@property (nonatomic, strong) NSString *next;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *comic;
@property (nonatomic, strong) NSString *hiddencomic;
@property (nonatomic, strong) NSString *alt;
@property (nonatomic, strong) NSString *news;
@property (nonatomic, strong) NSString *archive;
@property (nonatomic, strong) NSString *archivepart;
@property (nonatomic, strong) NSString *archivelink;
@property (nonatomic, strong) NSString *archivetitle;
@property (nonatomic, strong) NSMutableArray *archiveEntries;
@property (unsafe_unretained) id<WebcomicSiteDelegate> delegate;

@end