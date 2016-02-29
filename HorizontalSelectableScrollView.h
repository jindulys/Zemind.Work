//
//  HorizontalSelectableScrollView.h
//

#import <UIKit/UIKit.h>


@protocol HorizontalSelectableScrollViewDelegate;

typedef UIButton *(^CreateButtonBlock)(void);

@interface HorizontalSelectableScrollView : UIScrollView

@property (nonatomic, weak) id<HorizontalSelectableScrollViewDelegate> tapDelegate;
@property (nonatomic, copy) NSArray *titles;
@property (nonatomic, assign) int selectedIndex;

- (id)initWithTitles:(NSArray *)titles createTitleButtonBlock:(CreateButtonBlock)block;
- (id)initWithTitles:(NSArray *)titles;

/**
 *	@brief advanceSelectedIndexBy adjust selected Index by step
 *	@param step pos number means advance by step, nag number means fallback by step
 */
- (void)advanceSelectedIndexBy:(int)step;

/**
 *	@brief advance to next item of the scrollview, if reach the end, stay.
 */
- (void)advanceToNext;

/**
 *	@brief fallback to previous item of the scrollview, if reach the start, stay.
 */
- (void)fallbackToPrevious;

/**
 *	@brief setup subviews if scrollview is not set up in initial stage.
 */
- (void)setupSubviewsIfNeeded;

/**
 *	@brief clear scrollview's subviews in case we want to show new content.
 */
- (void)clearSubviews;

@end

@protocol HorizontalSelectableScrollViewDelegate <NSObject>

- (void)horizontalSelectableView:(HorizontalSelectableScrollView *)view selectIndex:(int)tappedIndex;

@end
