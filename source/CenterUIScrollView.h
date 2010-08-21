#import <UIKit/UIKit.h>


@interface CenterUIScrollView : UIScrollView {
	UIView *contentView;
	BOOL disableVerticalCentering;
	BOOL disableHorizontalCentering;
	CGPoint position;
	BOOL fixed;
	

}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property BOOL disableVerticalCentering;
@property BOOL disableHorizontalCentering;

-(void)fixPosition:(CGPoint)aPosition;
-(void)unfixPosition;

@end
