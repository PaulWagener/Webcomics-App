#import <Foundation/Foundation.h>


@interface Database : NSObject {

}

+(Database*) getDatabase;
-(void) addUnread:(int)site: (NSArray*)links;
-(void) removeUnread:(NSString*)link;
-(void) removeAllUnread:(int)site;
-(BOOL) isUnread:(NSString*)link;
-(int) getUnreadCount:(int)site;
-(void) updateSites:(NSArray*)sites;
-(NSArray*) getSites;
-(BOOL) hasNew:(int)site;
-(void) setNew:(int)site:(BOOL)new;
-(void) removeNew:(NSString*)url;
- (NSString*) getSiteDescription:(int)site;
-(void) updateSiteDescription:(int)site:(NSString*)description;
-(void) deleteSite:(int)site;
-(NSArray*) getMySites;
-(void) addMySite:(int)site;
-(void)deleteMySite:(int) site;
-(void) moveMySiteRow:(int)fromSite:(int)toSite;
- (NSArray*) getCustomSites;
- (void) addCustomSite:(NSString*)description;
- (NSString*) getLastComic:(int)site;
-(void) setLastComic:(int)site:(NSString*)lastcomic;
-(NSArray*) getBookmarkSites;
-(NSArray*) getBookmarkedComics:(int)site;
-(void)addBookmark:(int)site :(NSString*)title :(NSString*)url;
-(BOOL) isBookmarked:(NSString*)url;
-(void) deleteBookmark:(NSString*)url;
@end
