#import <UIKit/UIKit.h>
#import "WebcomicSite.h"
#import "ComicViewer.h"

@class ComicViewer;
@interface Archive : UIViewController<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
	IBOutlet UITableView *table;
	WebcomicSite *site;
	ComicViewer *comicViewer;
	int selectedComic;
}

- (id)initWithSite:(WebcomicSite*)site :(ComicViewer*)comicviewer;
-(void)setSelectedComic:(NSString*)comic;
@end
