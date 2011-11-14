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

//@protocol WebcomicSiteDelegate <NSObject>
//@optional
//- (void)archiveDownloaded:(WebcomicSite*)site;
//- (void)unreadUpdated:(WebcomicSite*)site;
//@end

@interface WebcomicSite : NSObject {
	enum archive_order archiveorder;
	
	NSURLConnection *archiveConnection;
	NSMutableData *archiveData;
	NSMutableArray *archiveEntries;
	long long expectedArchiveLength;
}

- (id) initWithString:(NSString*)string;
- (NSString*) getFullUrl:(NSString*)partialUrl;
- (NSString*) getPreviousUrl:(Comic*)aComic;
- (NSString*) getNextUrl:(Comic*)aComic;
- (NSString*) getLastComicUrl;
- (NSString*) getFirstComicUrl;
- (BOOL) hasArchive;
- (void) downloadArchive;
- (void) updateUnread;
- (bool) isLastFeature: (enum ComicFeature)feature;
- (enum ComicFeature) getPreviousFeature:(enum ComicFeature)feature;
- (enum ComicFeature) getNextFeature:(enum ComicFeature)feature;
- (void) validate;

	
@property int id;
@property (nonatomic, strong) NSString *name;

//URL to prepend to all found urls
@property (nonatomic, strong) NSString *base;

//URLS to first and last comic
@property (nonatomic, strong) NSString *first;
@property (nonatomic, strong) NSString *last;

//Stuff to find on a comic page
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *comic;
@property (nonatomic, strong) NSString *previous;
@property (nonatomic, strong) NSString *next;
@property (nonatomic, strong) NSString *hiddencomic;
@property (nonatomic, strong) NSString *hiddencomiclink;
@property (nonatomic, strong) NSString *alt;
@property (nonatomic, strong) NSString *news;

//Archive stuffs
@property (nonatomic, strong) NSString *archive;
@property (nonatomic, strong) NSString *archivepart;
@property (nonatomic, strong) NSString *archivelink;
@property (nonatomic, strong) NSString *archivetitle;
@property (nonatomic, strong) NSMutableArray *archiveEntries;
//@property (unsafe_unretained) id<WebcomicSiteDelegate> delegate;

@end