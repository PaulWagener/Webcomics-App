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

@synthesize id, name, base, first, last, previous, next, title, comic, hiddencomic, hiddencomiclink, alt, news, archive, archivepart, archivelink, archivetitle, archiveEntries;

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
   		if([substring hasPrefix:@"hiddencomiclink:"]) self.hiddencomiclink = [substring substringFromIndex:[@"hiddencomiclink:" length]];
		if([substring hasPrefix:@"alt:"]) self.alt = [substring substringFromIndex:[@"alt:" length]];
		if([substring hasPrefix:@"news:"]) self.news = [substring substringFromIndex:[@"news:" length]];
		if([substring hasPrefix:@"archive:"]) self.archive = [substring substringFromIndex:[@"archive:" length]];
		if([substring hasPrefix:@"archivepart:"]) self.archivepart = [substring substringFromIndex:[@"archivepart:" length]];
		if([substring hasPrefix:@"archivelink:"]) self.archivelink = [substring substringFromIndex:[@"archivelink:" length]];
		if([substring hasPrefix:@"archivetitle:"]) self.archivetitle = [substring substringFromIndex:[@"archivetitle:" length]];
		if([substring hasPrefix:@"archiveorder:"]) archiveorder = [[substring substringFromIndex:[@"archiveorder:" length]] isEqualToString:@"recenttop"] ? RECENTTOP : RECENTBOTTOM;
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
 * Returns wether this site has an archive
 */
-(BOOL) hasArchive {
	return self.archive != nil;
}

/**
 * Check if comic conforms to specification. This should be the case for all official comics in webcomiclist.txt.
 * People making a custom site might make a mistake, this method tells them what the mistake is.
 */
- (void) validate {
    if(!name)
        @throw [NSException exceptionWithName:@"" reason:@"Key 'name' not defined in definition" userInfo:nil];
    
    
    if (!comic)
        @throw [NSException exceptionWithName:@"" reason:@"Key 'comic' not defined in definition." userInfo:nil];
    
    if(hiddencomiclink && !hiddencomic)
        @throw [NSException exceptionWithName:@"" reason:@"If key 'hiddencomiclink' is not defined, key 'hiddencomic' should not be defined" userInfo:nil];
        
        
    
    if(archive) {
        if(first)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is defined, key 'first' should not be defined" userInfo:nil];
        
        if(previous)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is defined, key 'previous' should not be defined" userInfo:nil];
        
        if(next)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is defined, key 'next' should not be defined" userInfo:nil];
        
        if(last)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is defined, key 'last' should not be defined" userInfo:nil];
        
        if(!archivepart)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is defined, key 'archivepart' should also be defined" userInfo:nil];
        
        if(!archivelink)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is defined, key 'archivelink' should also be defined" userInfo:nil];
        
        if(!archivetitle)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is defined, key 'archivetitle' should also be defined" userInfo:nil];
       
    } else {
        if(!first)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is not defined, key 'first' should be defined" userInfo:nil];
        
        if(!previous)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is not defined, key 'previous' should be defined" userInfo:nil];
        
        if(!next)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is not defined, key 'next' should be defined" userInfo:nil];
        
        if(!last)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is not defined, key 'last' should be defined" userInfo:nil];
        
        if(archivepart)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is not defined, key 'archivepart' should also not be defined" userInfo:nil];
        
        if(archivelink)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is not defined, key 'archivelink' should also not be defined" userInfo:nil];
        
        if(archivetitle)
            @throw [NSException exceptionWithName:@"" reason:@"If key 'archive' is not defined, key 'archivetitle' should also not be defined" userInfo:nil];
       
    }
    

}
/**
 * Updates the database about the last comics that were read and added
 * Does networking so please do in a background thread.
 */
- (void) updateUnread {
	if([self hasArchive]) {
		[self downloadArchive];
        
  		//Update the unread entries
		NSString *lastcomic = [[Database getDatabase] getLastComic:self.id];
		if(lastcomic != nil) {
			NSMutableArray *unread = [[NSMutableArray alloc] init];
			
			int i = 0;
			ArchiveEntry *entry = [archiveEntries objectAtIndex:i];
			while(i < [archiveEntries count] && ![lastcomic isEqual:entry.link]) {
				[unread addObject:entry.link];
				entry = [archiveEntries objectAtIndex:i];
				i++;
			}
			
			[[Database getDatabase] addUnread:self.id :unread];
			
		}
        ArchiveEntry *recentEntry = [self.archiveEntries objectAtIndex:0];
		[[Database getDatabase] setLastComic:self.id :recentEntry.link];

	} else {
        /**
         * Check if a site has new comics displayed.
         * It stores the image-url of the latest comic in the 'lastcomic' field
         * Wether there are new comics is stored in 'hasnew'.
         */
        
        
        //Get the url of the last comic
		NSString *page = [NSString stringWithContentsOfURL:[NSURL URLWithString:self.last] encoding:NSUTF8StringEncoding error:nil];
        
        if (page == nil)
            return;
        
        
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
	}
}

-(void) doCheckLatestPageForNew {

}

#pragma mark -
#pragma mark Download Archive

/**
 * Downloads the archive synchronously.
 * The end result of this method is that archiveEntries are recent again
 * Might throw an exception when something goes wrong.
 */
-(void) downloadArchive {
   
    //TODO: Check here if it is really necessary to redownload the archive
	
	//Path of the file to store the contents of the downloaded archive page.
    NSString *archivePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
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
        }
    }
    
    NSError *error = nil;
    
    //(re-)download archive
    if(archiveString == nil) {
        archiveString = [NSString stringWithContentsOfURL:[NSURL URLWithString:self.archive] encoding:NSASCIIStringEncoding error:&error];
        
        if (!archiveString) {
            @throw [NSException exceptionWithName:nil reason:[NSString stringWithFormat:@"Could not download archive source from %s", self.archive.UTF8String] userInfo:nil];
        }
        
        [[NSFileManager defaultManager] createFileAtPath:archiveFile contents:[archiveString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    
    
    //Extract archive text
    NSString *archivePartString = [archiveString match:self.archivepart];

    if(!archivePartString)
        @throw [NSException exceptionWithName:nil reason:@"Could not match 'archivepart' on archive source" userInfo:nil];
        
    //Extract archive entries
    NSArray *links = [archivePartString matchAll:self.archivelink];
    NSArray *titles = [archivePartString matchAll:self.archivetitle];

    if(links.count == 0)
        @throw [NSException exceptionWithName:nil reason:@"No links captured with 'archivelink'" userInfo:nil];
    
    if(titles.count == 0)
        @throw [NSException exceptionWithName:nil reason:@"No titles captured with 'archivetitle'" userInfo:nil];
    
    if(links.count != titles.count)
        @throw [NSException exceptionWithName:nil reason:[NSString stringWithFormat:@"Captured a different amount of links and titles in archive (%d links vs %d titles", links.count, titles.count] userInfo:nil];
    
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

- (NSString*) getLastComicUrl {
    if([self hasArchive]) {
        ArchiveEntry *lastEntry = [archiveEntries objectAtIndex:0];
        return lastEntry.link;
    } else {
        return self.last;
    }
}
  
- (NSString*) getFirstComicUrl {
    if([self hasArchive]) {
        ArchiveEntry *firstEntry = [archiveEntries objectAtIndex:[archiveEntries count]-1];
        return firstEntry.link;
    } else {
        return self.first;
    }
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
