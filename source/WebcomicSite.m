//
//  WebcomicSite.m
//  WebComics
//
//  Created by Paul Wagener on 16-05-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WebcomicSite.h"
#import "Comic.h"
#import "ComicViewer.h"
#import "common.h"
#import "Database.h"

@implementation ArchiveEntry
@synthesize link, title;
@end

@implementation WebcomicSite

@synthesize id, name, base, first, last, previous, next, title, comic, hiddencomic, alt, news, archive, archivepart, archivelink, archivetitle, archiveEntries, delegate;

/**
 * Parse a string in the ▟█▙ format
 */
- (id) initWithString:(NSString*)string {
	self = [self init];
	NSArray *stringParts = [string componentsSeparatedByString:@"█"];
	int count = [stringParts count];
	
	for(int i = 0; i < count; i++) {
		NSString *substring = [stringParts objectAtIndex:i];
		if([substring hasPrefix:@"name:"]) self.name = [substring substringFromIndex:[@"name:" length]];
		if([substring hasPrefix:@"base:"]) self.base = [substring substringFromIndex:[@"base:" length]];
		if([substring hasPrefix:@"first:"]) self.first = [substring substringFromIndex:[@"first:" length]];
		if([substring hasPrefix:@"last:"]) self.last = [substring substringFromIndex:[@"last:" length]];
		if([substring hasPrefix:@"previous:"]) self.previous = [substring substringFromIndex:[@"previous:" length]];
		if([substring hasPrefix:@"next:"]) self.next = [substring substringFromIndex:[@"next:" length]];
		if([substring hasPrefix:@"title:"]) self.title = [substring substringFromIndex:[@"title:" length]];
		if([substring hasPrefix:@"comic:"]) self.comic = [substring substringFromIndex:[@"comic:" length]];
		if([substring hasPrefix:@"hiddencomic:"]) self.hiddencomic = [substring substringFromIndex:[@"hiddencomic:" length]];
		if([substring hasPrefix:@"alt:"]) self.alt = [substring substringFromIndex:[@"alt:" length]];
		if([substring hasPrefix:@"news:"]) self.news = [substring substringFromIndex:[@"news:" length]];
		if([substring hasPrefix:@"archive:"]) self.archive = [substring substringFromIndex:[@"archive:" length]];
		if([substring hasPrefix:@"archivepart:"]) self.archivepart = [substring substringFromIndex:[@"archivepart:" length]];
		if([substring hasPrefix:@"archivelink:"]) self.archivelink = [substring substringFromIndex:[@"archivelink:" length]];
		if([substring hasPrefix:@"archivetitle:"]) self.archivetitle = [substring substringFromIndex:[@"archivetitle:" length]];
		if([substring hasPrefix:@"archiveorder:"]) archiveorder = [[substring substringFromIndex:[@"archivetitle:" length]] isEqualToString:@"recenttop"] ? RECENTTOP : RECENTBOTTOM;
	}
	return self;	
}

/**
 * Prepends the base to the url to make it an absolute URL
 * e.g. turns /comic.html into http://site.com/comic.html
 */
- (NSString*) getFullUrl:(NSString*)partialUrl
{
	if(partialUrl == nil)
		return nil;
	
	//Remove ../ stuffs from the string
	partialUrl = [partialUrl stringByReplacingOccurrencesOfString:@"../" withString:@""];
	
	//Only prepend the base if the URL is not already absolute
	if(base != nil && ![partialUrl hasPrefix:@"http://"]) {
		partialUrl = [base stringByAppendingString:partialUrl];
	}
	return partialUrl;
}

/**
 * Returns wether this site uses an archive for next/previous navigation
 */
-(BOOL) usesArchiveForComics {
	return self.archive != nil;
}

/**
 * Returns wether this site has an archive but is incomplete so it can only be used for recent comics
 */
-(BOOL) hasArchive {
	return self.archive != nil;
}

-(void) updateUnread {
	if([self hasArchive]) {
		[self downloadArchive];
	} else {
		[self performSelectorInBackground:@selector(doCheckLatestPageForNew) withObject:self];
	}
}

/**
 * Check if a site has new comics displayed.
 * It stores the image-url of the latest comic in the 'lastcomic' field
 * Wether there are new comics is stored in 'hasnew'.
 */
-(void) doCheckLatestPageForNew {
	@autoreleasepool {
	
	//Get the url of the last comic
		NSString *page = [NSString stringWithContentsOfURL:[NSURL URLWithString:self.last] encoding:NSASCIIStringEncoding error:nil];
                      
                      
		NSString *lastComicUrl = [page match:self.comic];

		//Compare with the last known strip in the database
		//(unless this is the first time this strip is checked)
		NSString *lastKnownComicUrl = [[Database getDatabase] getLastComic:self.id];
		if(lastKnownComicUrl != nil && ![lastComicUrl isEqualToString:lastKnownComicUrl]) {
			
			//It's different, save so in the database
			[[Database getDatabase] setNew:self.id :YES];
		}
		
		//Save new latest url for future comparisons
		[[Database getDatabase] setLastComic:self.id :lastComicUrl];

		if([delegate respondsToSelector:@selector(unreadUpdated:)]) {
			[delegate unreadUpdated:self];
		}
	
	}
}

#pragma mark -
#pragma mark Download Archive

/**
 * Start downloading the archive page so we know where all the comics are
 */
-(void) downloadArchive {
	if(![self usesArchiveForComics])
		return;
	
	[self performSelectorInBackground:@selector(doDownloadArchive) withObject:self];
}

-(void) doDownloadArchive {
	@autoreleasepool {
	
	//Path of the file to store the contents of the downloaded archive page.
		NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		NSString *archivePath = [documentPath stringByAppendingPathComponent:@"archive"];
		[[NSFileManager defaultManager] createDirectoryAtPath:archivePath withIntermediateDirectories:YES attributes:nil error:nil]; //Only really does something first time executed
		NSString *archiveFile = [archivePath stringByAppendingPathComponent:[NSString stringWithFormat:@"archive-%i.html", self.id]];

		NSString *archiveString = nil;
		
		//Try accessing the modification date of the archive file
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:archiveFile error:nil];
		if(attributes != nil) {
			NSDate *date = [attributes fileModificationDate];
			NSTimeInterval archiveAge = [[NSDate date] timeIntervalSinceDate:date];
			
			//If archive is less than 10 minutes old we can still use it
			if(archiveAge < 60 * 10) {
				archiveString = [NSString stringWithContentsOfFile:archiveFile encoding:NSASCIIStringEncoding error:nil];
				NSLog(@"From Cache");
			}
		}
		
		//(re-)download archive
		if(archiveString == nil) {
			archiveString = [NSString stringWithContentsOfURL:[NSURL URLWithString:self.archive]encoding:NSASCIIStringEncoding error:nil];	
			[[NSFileManager defaultManager] createFileAtPath:archiveFile contents:[archiveString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
		}
		
		
		//Extract archive text
		NSString *archivePartString = [archiveString match:self.archivepart];
		
		//Extract archive entries
		NSArray *links = [archivePartString matchAll:self.archivelink];
		NSArray *titles = [archivePartString matchAll:self.archivetitle];
		
		self.archiveEntries = [[NSMutableArray alloc] init];
		
		int count = [links count];
		for(int i = 0; i < count; i++) {
			ArchiveEntry *archiveEntry = [[ArchiveEntry alloc] init];
			archiveEntry.link = [self getFullUrl:[links objectAtIndex:i]];
			NSString *entryTitle = [titles objectAtIndex:i];
			archiveEntry.title = [entryTitle stringByDecodingXMLEntities];
			[archiveEntries addObject:archiveEntry];
		}
		
		//Make sure the first archive entry is the most recent one
		if(archiveorder == RECENTBOTTOM)
			[archiveEntries reverse];
		
		//Find the first and the last comic
		ArchiveEntry *firstEntry = [archiveEntries objectAtIndex:[archiveEntries count]-1];
		ArchiveEntry *lastEntry = [archiveEntries objectAtIndex:0];
		self.first = firstEntry.link;
		self.last = lastEntry.link;
		
		//Update the unread entries
		NSString *lastcomic = [[Database getDatabase] getLastComic:self.id];
		if(lastcomic != nil) {
			NSMutableArray *unread = [[NSMutableArray alloc] init];
			
			int i = 0;
			ArchiveEntry *entry = [archiveEntries objectAtIndex:i];
			while(i < [archiveEntries count] && ![lastcomic isEqual:entry.link]) {
				[unread addObject:entry.link];
				i++;
				entry = [archiveEntries objectAtIndex:i];
			}
			
			[[Database getDatabase] addUnread:self.id :unread];
			
		}
		[[Database getDatabase] setLastComic:self.id :self.last];
	
	}
	[self performSelectorOnMainThread:@selector(finishDownloadArchive) withObject:self waitUntilDone:NO];
}

-(void) finishDownloadArchive {
	if(delegate) {
		if([delegate respondsToSelector:@selector(unreadUpdated:)]) {
			[delegate unreadUpdated:self];
		}

		if([delegate respondsToSelector:@selector(archiveDownloaded:)])
			[delegate archiveDownloaded:self];
	}
}

-(int)findArchiveIndex:(NSString*)link {
	for(int i = 0; i < [archiveEntries count]; i++) {
		ArchiveEntry *archiveEntry = [archiveEntries objectAtIndex:i];
		if([archiveEntry.link isEqualToString:link]) {
			return i;
		}
	}
	return -1;
}

/**
 * Find for a given comic the url for the next/previous comic
 * For comics with an archive this can be looked up within the archiveEntries
 * For comics without an archive the comic has probably filled up its previous/nextUrl variables with the correct url
 */

-(NSString*) getPreviousUrl:(Comic*)aComic {
	if(aComic.previousUrl != nil)
		return aComic.previousUrl;
	
	int archiveIndex = [self findArchiveIndex:aComic.url];
	if(archiveIndex >= [archiveEntries count]-1 || archiveIndex == -1)
		return nil;
	
	ArchiveEntry *previousEntry = [archiveEntries objectAtIndex:archiveIndex+1];
	return previousEntry.link;
}

-(NSString*) getNextUrl:(Comic*)aComic {
	if(aComic.nextUrl != nil)
		return aComic.nextUrl;
	
	int archiveIndex = [self findArchiveIndex:aComic.url];
	if(archiveIndex <= 0)
		return nil;
	
	ArchiveEntry *previousEntry = [archiveEntries objectAtIndex:archiveIndex-1];
	return previousEntry.link;
}

#pragma mark -
#pragma mark Features

/**
 * The proper order of features for a comic is: mainComic, altText, hiddenComic, news
 * However most comics only have a subset of these features
 * isLastFeature, getPreviousFeature & getNextFeature are methods for ComicViewer to find out which features of a comic to show
 */

-(bool) isLastFeature: (enum ComicFeature)feature {
	enum ComicFeature lastFeature;
	if(self.news != nil) {
		lastFeature = newsFeature;
	} else if(self.hiddencomic != nil) {
		lastFeature = hiddenComicFeature;
	} else if(self.alt != nil) {
		lastFeature = altTextFeature;
	} else {
		lastFeature = mainComicFeature;
	}
	return feature == lastFeature;
}

-(enum ComicFeature) getPreviousFeature:(enum ComicFeature)feature {
	if(feature == newsFeature)
		return self.hiddencomic != nil ? hiddenComicFeature : [self getPreviousFeature:hiddenComicFeature];
	
	if(feature == hiddenComicFeature && self.alt != nil)
		return altTextFeature;

	return mainComicFeature;
}

-(enum ComicFeature) getNextFeature:(enum ComicFeature)feature {
	if(feature == mainComicFeature)
		return self.alt != nil ? altTextFeature : [self getNextFeature:altTextFeature];
	
	if(feature == altTextFeature && self.hiddencomic != nil)
		return hiddenComicFeature;
	
	return newsFeature;
}

@end
