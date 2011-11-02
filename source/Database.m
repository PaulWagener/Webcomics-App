//
//  Database.m
//  WebComics
//
//  Created by Paul Wagener on 07-08-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Database.h"
#import "common.h"
#import "WebcomicSite.h"
#import "UpdateViewController.h"
#import <sqlite3.h>

static sqlite3* database;
static sqlite3_stmt *compiledStatement;
static Database* databaseInstance;

@implementation Database

+(Database*) getDatabase {
	if(databaseInstance == nil) {
		databaseInstance = [[Database alloc] init];
	}
	return databaseInstance;
}


/**
 * Open the database and create the database structure if necessary
 */
-(id) init {
	self = [super init];		
	
	//Open database
	NSString *databasePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	databasePath = [databasePath stringByAppendingPathComponent:@"webcomics.sqlite"];
	BOOL databaseEmpty = ![[NSFileManager defaultManager] fileExistsAtPath:databasePath];
	sqlite3_open([databasePath UTF8String], &database);
	
	//If there is no database file yet we have to create the 
	if(databaseEmpty) {
		sqlite3_exec(database, "CREATE TABLE unreadcomics ( site INTEGER, link VARCHAR(300) PRIMARY KEY);", NULL, NULL, NULL);
		sqlite3_exec(database, "CREATE TABLE sites ( id INTEGER PRIMARY KEY, name VARCHAR(100), description VARCHAR(1000));", NULL, NULL, NULL);
		sqlite3_exec(database, "CREATE TABLE mysites (site text PRIMARY KEY,rank integer,lastcomic text, hasnew INTEGER);", NULL, NULL, NULL);
		sqlite3_exec(database, "CREATE TABLE bookmarks (site INTEGER, title VARCHAR(100), url VARCHAR(300) PRIMARY KEY);", NULL, NULL, NULL);
		
		
		//Populate database with local site definitions
		NSString *listString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"webcomiclist" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
		[UpdateViewController doUpdateWithString:listString];
	}
	
	return self;
}


#pragma mark -
#pragma mark Unread Comics
/**
 * Add a list of comics as 'new'
 */
-(void) addUnread:(int)site: (NSArray*)links {
	sqlite3_exec(database, "BEGIN", NULL, NULL, NULL);
	for(int i = 0; i < [links count]; i++) {
		NSString *link = [links objectAtIndex:i];
		sqlite3_prepare_v2(database, "INSERT INTO unreadcomics VALUES(?,?)", -1, &compiledStatement, nil);
		sqlite3_bind_int(compiledStatement, 1, site);
		sqlite3_bind_text(compiledStatement, 2, [link UTF8String], -1, SQLITE_STATIC);
		sqlite3_step(compiledStatement);
	}
	sqlite3_exec(database, "COMMIT", NULL, NULL, NULL);
}

/**
 * Remove 'new' status of a comic
 * Also known as reading the comic
 */
-(void) removeUnread:(NSString*)link {
	sqlite3_prepare_v2(database, "DELETE FROM unreadcomics WHERE link = ?", -1, &compiledStatement, nil);
	sqlite3_bind_text(compiledStatement, 1, [link UTF8String], -1, SQLITE_STATIC);
	sqlite3_step(compiledStatement);
}

/**
 * Remove 'new' status of all comics
 */
-(void) removeAllUnread:(int)site {
	sqlite3_prepare_v2(database, "DELETE FROM unreadcomics WHERE site = ?", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, site);
	sqlite3_step(compiledStatement);
}



/**
 * Find out if a comic is 'new'
 */
-(BOOL) isUnread:(NSString*)link {
	sqlite3_prepare_v2(database, "SELECT link FROM unreadcomics WHERE link = ?", -1, &compiledStatement, nil);
	sqlite3_bind_text(compiledStatement, 1, [link UTF8String], -1, SQLITE_STATIC);
	return sqlite3_step(compiledStatement) == SQLITE_ROW;
}

/**
 * Get the amount of comics still to be read for this site
 */
-(int) getUnreadCount:(int)site {
	sqlite3_prepare_v2(database, "SELECT COUNT(link) FROM unreadcomics WHERE site = ?", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, site);
	sqlite3_step(compiledStatement);
	return sqlite3_column_int(compiledStatement, 0);
}

#pragma mark -
#pragma mark Sites

/**
 * Get a list of all sites
 */
-(NSArray*) getSites {
	NSMutableArray *sites = [[NSMutableArray alloc] init];
	sqlite3_prepare_v2(database, "SELECT id, description FROM sites WHERE id > 0 ORDER BY name", -1, &compiledStatement, nil);

	while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
		int id = sqlite3_column_int(compiledStatement, 0);
		NSString *description = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];

		WebcomicSite *site = [[WebcomicSite alloc] initWithString:description];
		site.id = id;
		[sites addObject:site];
	}
	return sites;
}
	
/**
 * Take a list of strings and put them in the database
 * Add ones that don't exist yet, update existing ones and delete ones that are just empty strings
 */
-(void) updateSites:(NSArray*)sites {

	sqlite3_exec(database, "BEGIN", NULL, NULL, NULL);	
	
	//Skip first one as it only contains revision information
	for(int i = 1; i < [sites count]; i++) {
		NSString *definition = [sites objectAtIndex:i];
		NSString *name = [definition match:@"█name:(.*?)█"];

		if(name == nil) {
			//Comic was here but is no longer online/functional
			sqlite3_prepare_v2(database, "DELETE FROM sites WHERE id = ?", -1, &compiledStatement, nil);
			sqlite3_bind_int(compiledStatement, 1, i);
		} else {
			//Update/insert comic
			sqlite3_prepare_v2(database, "REPLACE INTO sites VALUES(?,?,?)", -1, &compiledStatement, nil);
			sqlite3_bind_int(compiledStatement, 1, i);
			sqlite3_bind_text(compiledStatement, 2, [name UTF8String], -1, SQLITE_STATIC);
			sqlite3_bind_text(compiledStatement, 3, [definition UTF8String], -1, SQLITE_STATIC);
		}
		sqlite3_step(compiledStatement);
	}

	sqlite3_exec(database, "COMMIT", NULL, NULL, NULL);
}

/**
 * Delete a site from the database.
 * Is typically only used for custom sites
 */
-(void) deleteSite:(int)site {
	sqlite3_prepare_v2(database, "DELETE FROM sites WHERE id = ?", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, site);
	sqlite3_step(compiledStatement);
	
	//Delete all custom sites linked to it
	sqlite3_prepare_v2(database, "DELETE FROM mysites WHERE site = ?", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, site);
	sqlite3_step(compiledStatement);	
}

- (NSString*) getSiteDescription:(int)site {
	sqlite3_prepare_v2(database, "SELECT description FROM sites WHERE id = ?", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, site);
	sqlite3_step(compiledStatement);
	
	return [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 0)];
}

-(void) updateSiteDescription:(int)site:(NSString*)description {
	sqlite3_prepare_v2(database, "UPDATE sites SET description = ? WHERE id = ?", -1, &compiledStatement, nil);
	sqlite3_bind_text(compiledStatement, 1, [description UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_int(compiledStatement, 2, site);
	sqlite3_step(compiledStatement);
}


#pragma mark -
#pragma mark MySites

/**
 * Get a list of all the sites selected by the user
 */
-(NSArray*) getMySites {
	NSMutableArray *mysites = [[NSMutableArray alloc] init];
	sqlite3_prepare_v2(database, "SELECT id, description FROM mysites INNER JOIN sites ON mysites.site = sites.id ORDER BY rank", -1, &compiledStatement, nil);
	
	while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
		int id = sqlite3_column_int(compiledStatement, 0);
		NSString *description = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];

		WebcomicSite *site = [[WebcomicSite alloc] initWithString:description];
		site.id = id;
		[mysites addObject:site];
	}
	return mysites;
}

/**
 * Add a site to the bottom of the users personal list
 */
-(void)addMySite:(int) site {
	sqlite3_prepare_v2(database, "SELECT MAX(rank) FROM mysites", -1, &compiledStatement, nil);
	sqlite3_step(compiledStatement);
	int maxrank = sqlite3_column_int(compiledStatement, 0);

	sqlite3_prepare_v2(database, "INSERT INTO mysites VALUES(?,?, NULL, 0)", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, site);
	sqlite3_bind_int(compiledStatement, 2, maxrank+1);
	sqlite3_step(compiledStatement);
}


/**
 * Remove a site from the users list
 */
-(void)deleteMySite:(int) site {
	if(site < 0) {
		//If it's a custom site just delete the entire site
		[self deleteSite:site];
	} else {
		sqlite3_prepare_v2(database, "DELETE FROM mysites WHERE site = ?", -1, &compiledStatement, nil);
		sqlite3_bind_int(compiledStatement, 1, site);
		sqlite3_step(compiledStatement);
	}
}

/**
 * Move a row to a different position in the table by changing rank values
 */
-(void) moveMySiteRow:(int)fromSite:(int)toSite {
	if(fromSite == toSite)
		return;
	
	//Get rank of dragged site
	sqlite3_prepare_v2(database, "SELECT rank FROM mysites WHERE site = ?", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, fromSite);
	sqlite3_step(compiledStatement);
	int fromSiteRank = sqlite3_column_int(compiledStatement, 0);
	
	//Get rank of the site that fromSite is going to replace
	sqlite3_prepare_v2(database, "SELECT rank FROM mysites WHERE site = ?", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, toSite);
	sqlite3_step(compiledStatement);
	int toSiteRank = sqlite3_column_int(compiledStatement, 0);
	
	BOOL movingDown = toSiteRank > fromSiteRank;

	//Move all intermediate rows
	const char *sql;
	if(movingDown)
		sql = "UPDATE mysites SET rank = rank - 1 WHERE rank > ? AND rank <= ?";
	else
		sql = "UPDATE mysites SET rank = rank + 1 WHERE rank < ? AND rank >= ?";

	sqlite3_prepare_v2(database, sql, -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, fromSiteRank);
	sqlite3_bind_int(compiledStatement, 2, toSiteRank);
	sqlite3_step(compiledStatement);
	
	//Set rank of the moved row to the rank of the replaced row
	sqlite3_prepare_v2(database, "UPDATE mysites SET rank = ? WHERE site = ?", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, toSiteRank);
	sqlite3_bind_int(compiledStatement, 2, fromSite);
	sqlite3_step(compiledStatement);
}

/**
 * Get & Set the last comic field
 */
- (NSString*) getLastComic:(int)site {
	sqlite3_prepare_v2(database, "SELECT lastcomic FROM mysites WHERE site = ?", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, site);
	sqlite3_step(compiledStatement);
	
	const unsigned char *lastcomic = sqlite3_column_text(compiledStatement, 0);
	if(lastcomic == nil)
		return nil;
	else
		return [NSString stringWithUTF8String:(char*)lastcomic];
}

-(void) setLastComic:(int)site:(NSString*)lastcomic {
	sqlite3_prepare_v2(database, "UPDATE mysites SET lastcomic = ? WHERE site = ?", -1, &compiledStatement, nil);
	sqlite3_bind_text(compiledStatement, 1, [lastcomic UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_int(compiledStatement, 2, site);
	sqlite3_step(compiledStatement);
}

/**
 * Get & Set the hasnew field
 */
- (BOOL) hasNew:(int)site {
	sqlite3_prepare_v2(database, "SELECT hasnew FROM mysites WHERE site = ?", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, site);
	sqlite3_step(compiledStatement);
	return sqlite3_column_int(compiledStatement, 0);
}

-(void) setNew:(int)site:(BOOL)new {
	sqlite3_prepare_v2(database, "UPDATE mysites SET hasnew = ? WHERE site = ?", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, new);
	sqlite3_bind_int(compiledStatement, 2, site);
	sqlite3_step(compiledStatement);
}

-(void) removeNew:(NSString*)url {
	sqlite3_prepare_v2(database, "UPDATE mysites SET hasnew = 0 WHERE lastcomic = ?", -1, &compiledStatement, nil);
	sqlite3_bind_text(compiledStatement, 1, [url UTF8String], -1, SQLITE_STATIC);
	sqlite3_step(compiledStatement);	
}

#pragma mark Custom Sites

/**
 * Get a list of sites defined by the user himself
 */
- (NSArray*) getCustomSites {
	NSMutableArray *sites = [[NSMutableArray alloc] init];
	sqlite3_prepare_v2(database, "SELECT id, description FROM sites WHERE id < 0 ORDER BY name", -1, &compiledStatement, nil);
	
	while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
		int id = sqlite3_column_int(compiledStatement, 0);
		NSString *description = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
		
		WebcomicSite *site = [[WebcomicSite alloc] initWithString:description];
		site.id = id;
		[sites addObject:site];
	}
	return sites;
}

/**
 * Add a new custom site to the database
 */
- (void) addCustomSite:(NSString*)description {
	//Get the name of the site
	WebcomicSite *site = [[WebcomicSite alloc] initWithString:description];
	NSString *name = site.name;
	
	//Find a new id below 0
	sqlite3_prepare_v2(database, "SELECT MIN(id) FROM sites", -1, &compiledStatement, nil);
	sqlite3_step(compiledStatement);
	int minSiteId = MIN(0, sqlite3_column_int(compiledStatement, 0));
	
	//Add custom site
	sqlite3_prepare_v2(database, "INSERT INTO sites VALUES(?,?,?)", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, minSiteId - 1);
	sqlite3_bind_text(compiledStatement, 2, [name UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(compiledStatement, 3, [description UTF8String], -1, SQLITE_STATIC);
	sqlite3_step(compiledStatement);
	
	[self addMySite:minSiteId-1];
}

#pragma mark Bookmarks -

/**
 * Get a list of sites that have bookmarked comics in their archives
 */
-(NSArray*) getBookmarkSites {
	NSMutableArray *sites = [[NSMutableArray alloc] init];
	sqlite3_prepare_v2(database, "SELECT DISTINCT site, description FROM bookmarks INNER JOIN sites ON site = id ORDER BY name", -1, &compiledStatement, nil);
	
	while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
		int id = sqlite3_column_int(compiledStatement, 0);
		NSString *description = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
		
		WebcomicSite *site = [[WebcomicSite alloc] initWithString:description];
		site.id = id;
		[sites addObject:site];
	}
	return sites;
}

/**
 * Get a list of bookmarked comics for a specific site
 */
-(NSArray*) getBookmarkedComics:(int)site {
	NSMutableArray *comics = [[NSMutableArray alloc] init];
	sqlite3_prepare_v2(database, "SELECT title, url FROM bookmarks WHERE site = ? ORDER BY title", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, site);
	
	while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
		char* charTitle = (char *)sqlite3_column_text(compiledStatement, 0);
		NSString *title;
		if(charTitle == nil)
			title = @"Comic";
		else
			title = [NSString stringWithUTF8String:charTitle];
		
		NSString *url = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];

		[comics addObject:[NSArray arrayWithObjects:title,url,nil]];
	}
	return comics;
}

/**
 * Returns wether a specific URL was already bookmarked
 */
-(BOOL) isBookmarked:(NSString*)url {
	sqlite3_prepare_v2(database, "SELECT url FROM bookmarks WHERE url = ?", -1, &compiledStatement, nil);
	sqlite3_bind_text(compiledStatement, 1, [url UTF8String], -1, SQLITE_STATIC);
	return sqlite3_step(compiledStatement) == SQLITE_ROW;
}

/**
 * Add a bookmark with a specific site, title and url
 */
-(void)addBookmark:(int)site :(NSString*)title :(NSString*)url {
	sqlite3_prepare_v2(database, "INSERT INTO bookmarks VALUES(?,?,?)", -1, &compiledStatement, nil);
	sqlite3_bind_int(compiledStatement, 1, site);
	sqlite3_bind_text(compiledStatement, 2, [title UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(compiledStatement, 3, [url UTF8String], -1, SQLITE_STATIC);
	sqlite3_step(compiledStatement);
}

/**
 * Remove a bookmark
 */
-(void) deleteBookmark:(NSString*)url {
	sqlite3_prepare_v2(database, "DELETE FROM bookmarks WHERE url = ?", -1, &compiledStatement, nil);
	sqlite3_bind_text(compiledStatement, 1, [url UTF8String], -1, SQLITE_STATIC);
	sqlite3_step(compiledStatement);
}


@end
