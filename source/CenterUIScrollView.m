#import "CenterUIScrollView.h"
#import "ComicViewer.h"

@implementation CenterUIScrollView

@synthesize contentView, disableVerticalCentering, disableHorizontalCentering;

/**
 * Implements tap to zoom, has nothing to do with centering
 */
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	
	UITouch *touch = [[event allTouches] anyObject];

	if([touch tapCount] == 1) {
		[self performSelector:@selector(singleTap) withObject:nil afterDelay:0.5];
	}
	
	if ([touch tapCount] == 2)
	{
		//Cancel singleTap action
		[NSObject cancelPreviousPerformRequestsWithTarget:self];

		if(self.zoomScale >= 1.0)
			//Zoom out to show everything
			[self setZoomScale:self.minimumZoomScale animated:YES];
		else {
			//Zoom in to the point the user tapped
			CGPoint location = [touch locationInView:contentView];

			CGFloat width = self.bounds.size.width;
			CGFloat height = self.bounds.size.height;
			
			self.contentMode = UIViewContentModeCenter;
			[self zoomToRect:CGRectMake(location.x-width/2, location.y - height/2, width, height) animated:YES];
		} 
	}
}

-(void) singleTap {
	ComicViewer *viewer = (ComicViewer*)self.delegate;
    [viewer showUI];
}

-(void)fixPosition:(CGPoint)aPosition {
	fixed = YES;
	position = aPosition;
}

-(void)unfixPosition {
	fixed = NO;
}

/**
 * This function adjusts the contentViews frame so that it is always centered
 * in this scrollView. This is only done if the zoom is viewed out enough to do it.
 */
-(void)layoutSubviews
{
	[super layoutSubviews];
	
	//Force the contentOffset to be a specific value, don't do any centering
	if(fixed) {
		self.contentOffset = position;
		return;
	}
	
	CGRect imageFrame = contentView.frame;
	
	if(!disableVerticalCentering) {	
		//Center the image vertically
		if(imageFrame.size.height < self.bounds.size.height) {
			imageFrame.origin.y = (self.bounds.size.height - imageFrame.size.height) / 2;
		} else {
			imageFrame.origin.y = 0;
		}
	}	
	
	if(!disableHorizontalCentering) {	
		//Center the image horizontally
		if(imageFrame.size.width < self.bounds.size.width)
			imageFrame.origin.x = (self.bounds.size.width - imageFrame.size.width) / 2;	
		else
			imageFrame.origin.x = 0;
	}
	
	self.contentView.frame = imageFrame;
}

/**
 * Use only THIS method to add a subview to this scrollview
 * Be sure to know what you are doing if you use the regular functions
 */
- (void)setContentView:(UIView *)view {
	//Remove old contentView
	if(self.contentView != nil) {
		[self.contentView removeFromSuperview];
	}
	
	self.contentView = view;
	[super addSubview:view];
}

@end
