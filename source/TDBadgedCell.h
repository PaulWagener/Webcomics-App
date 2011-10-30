//
//  TDBadgedCell.h
//  TDBadgedTableCell
//	TDBageView
//
//	Any rereleasing of this code is prohibited.
//	Please attribute use of this code within your application
//
//	Any Queries should be directed to hi@tmdvs.me | http://www.tmdvs.me
//	
//  Created by Tim on [Dec 30].
//  Copyright 2009 Tim Davies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDBadgeView : UIView
{
	UIFont *font;
}

@property (nonatomic, readonly) NSUInteger width;
@property (nonatomic, assign) NSUInteger badgeNumber;
@property (nonatomic, assign) UITableViewCell *parent;
@property (nonatomic, strong) UIColor *badgeColor;
@property (nonatomic, strong) UIColor *badgeColorHighlighted;

@end

@interface TDBadgedCell : UITableViewCell {
	NSInteger badgeNumber;
	TDBadgeView *badge;
	
	UIColor *badgeColor;
	UIColor *badgeColorHighlighted;
}

@property NSInteger badgeNumber;
@property (readonly, strong) TDBadgeView *badge;
@property (nonatomic, strong) UIColor *badgeColor;
@property (nonatomic, strong) UIColor *badgeColorHighlighted;

@end
