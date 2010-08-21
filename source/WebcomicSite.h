//
//  WebcomicSite.h
//  WebComics
//
//  Created by Paul Wagener on 16-05-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Comic;

enum archive_order {
	RECENTTOP,
	RECENTBOTTOM
};

@interface ArchiveEntry : NSObject {
	NSString *link;
	NSString *title;
};
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *title;
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
	
	id<WebcomicSiteDelegate> delegate;
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
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *base;
@property (nonatomic, retain) NSString *last;
@property (nonatomic, retain) NSString *first;
@property (nonatomic, retain) NSString *previous;
@property (nonatomic, retain) NSString *next;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *comic;
@property (nonatomic, retain) NSString *hiddencomic;
@property (nonatomic, retain) NSString *alt;
@property (nonatomic, retain) NSString *news;
@property (nonatomic, retain) NSString *archive;
@property (nonatomic, retain) NSString *archivepart;
@property (nonatomic, retain) NSString *archivelink;
@property (nonatomic, retain) NSString *archivetitle;
@property (nonatomic, retain) NSMutableArray *archiveEntries;
@property (assign) id<WebcomicSiteDelegate> delegate;

@end