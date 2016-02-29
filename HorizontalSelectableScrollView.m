//
//  HorizontalSelectableScrollView.m
//

#import "HorizontalSelectableScrollView.h"
#import "PureLayout.h"
#import <StuffCommon/Categories.h>

static const float kHorizontalItemSpace = 20.0;

@interface HorizontalSelectableScrollView()

@property (nonatomic, copy) NSArray *titleButtons;
@property (nonatomic, assign) BOOL hasSetConstraints;
@property (nonatomic, assign) BOOL animating;
@property (nonatomic, copy) CreateButtonBlock createTitleButtonBlock;

// Constraints
@property (nonatomic, copy) NSArray *initialPortraitConstraints;
@property (nonatomic, copy) NSArray *initialLandscapeConstraints;
@property (nonatomic, copy) NSArray *activePortraitConstraints;
@property (nonatomic, copy) NSArray *activeLandscapeConstraints;

@end

@implementation HorizontalSelectableScrollView

- (id)initWithTitles:(NSArray *)titles {
	CreateButtonBlock defaultTitleButtonBlock = [self defaultCreateButtonBlock];
	return [self initWithTitles:titles createTitleButtonBlock:defaultTitleButtonBlock];
}

- (id)initWithTitles:(NSArray *)titles createTitleButtonBlock:(CreateButtonBlock)block {
	if (self = [super initWithFrame:CGRectZero]) {
		self.titles = titles;
		self.createTitleButtonBlock = block;
		self.backgroundColor = [UIColor homeHeaderBackGroundColour];
		self.showsHorizontalScrollIndicator = NO;
		// Register Notification for rotation
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
		if (self.titles && [self.titles count] > 0) {
			[self setupSubviewsIfNeeded];
		}
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	return [self initWithTitles:nil];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	return [self initWithTitles:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma mark - Setup and layout Views

- (void)setupSubViews {
	NSMutableArray *titleButtonConsArray = [[NSMutableArray alloc] initWithCapacity:self.titles.count];
	
	[self.titles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		UIButton *button = self.createTitleButtonBlock();
		[button setTitle:(NSString *)obj forState:UIControlStateNormal];
		[button addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
		
		[self addSubview:button];
		[titleButtonConsArray addObject:button];
	}];
	self.titleButtons = [titleButtonConsArray copy];
}

- (void)updateConstraints {
	if (!self.hasSetConstraints) {
		[self setupConstraints];
		self.hasSetConstraints = YES;
	}
	[super updateConstraints];
}

- (void)setupConstraints {
	NSArray *constraints = [self createTitleButtonConstraintsWithHorizontalSpace:kHorizontalItemSpace];
	
	self.initialLandscapeConstraints = constraints;
	self.initialPortraitConstraints = constraints;
	self.activeLandscapeConstraints = nil;
	self.activePortraitConstraints = nil;
	
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
		self.activeLandscapeConstraints = self.initialLandscapeConstraints;
	} else {
		self.activePortraitConstraints = self.initialPortraitConstraints;
	}
}

- (NSArray *)createTitleButtonConstraintsWithHorizontalSpace:(CGFloat)space {
	NSMutableArray *constraints = [[NSMutableArray alloc] init];
	
	NSUInteger titleCount = self.titleButtons.count;
	
	UIButton *prevButton = nil;
	for (int i = 0; i < titleCount; i++) {
		UIButton *button = (UIButton *)[self.titleButtons objectAtIndex:i];
		
		NSLayoutConstraint *horizontalAxisConstraint = [button autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self];
		[constraints addObject:horizontalAxisConstraint];
		
		if (!prevButton) {
			NSLayoutConstraint *firstLeadingConstraint = [button autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:space/2.0];
			[constraints addObject:firstLeadingConstraint];
		} else {
			NSLayoutConstraint *lastTrailingConstraint = [button autoConstrainAttribute:ALAttributeLeading toAttribute:ALAttributeTrailing ofView:prevButton withOffset:space];
			[constraints addObject:lastTrailingConstraint];
		}
		
		if (i == titleCount - 1) {
			NSLayoutConstraint *trailingConstraint = [button autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:space/2.0];
			[constraints addObject:trailingConstraint];
		}
		prevButton = button;
	}
	return [constraints copy];
}

- (void)layoutSubviews {
	// Do the first layout pass round to use current constraints to generate layout information.
	[super layoutSubviews];
	
	CGFloat screenWidth = self.window.frame.size.width;
	UIButton *lastButton = (UIButton *)self.titleButtons.lastObject;
	if (lastButton != nil && CGRectGetMaxX(lastButton.frame) < screenWidth - kHorizontalItemSpace) {
		// You should update your constraints here
		CGFloat totalButtonWidth = 0.0f;
		for (UIButton *button in self.titleButtons) {
			CGFloat currentWidth = button.frame.size.width;
			totalButtonWidth += currentWidth;
		}
		
		CGFloat reasonableSpace = (screenWidth - totalButtonWidth) / (self.titleButtons.count + 1);
		
		// Deactive all possible active Constraints for both Portrait and Landscape Mode.
		[NSLayoutConstraint deactivateConstraints:self.activePortraitConstraints];
		[NSLayoutConstraint deactivateConstraints:self.activeLandscapeConstraints];
		UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
		if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
			// Create and active valid Landscape constraints.
			self.activeLandscapeConstraints = [self createTitleButtonConstraintsWithHorizontalSpace:reasonableSpace];
			[NSLayoutConstraint activateConstraints:self.activeLandscapeConstraints];
		} else {
			// Create and active valid Portrait constraints.
			self.activePortraitConstraints = [self createTitleButtonConstraintsWithHorizontalSpace:reasonableSpace];
			[NSLayoutConstraint activateConstraints:self.activePortraitConstraints];
		}
		
		// You then trigger layout subview here, do not trigger outside, otherwise you could cause infinite layout.
		[super layoutSubviews];
	}
}

- (void)didRotate:(NSNotification *)notification {
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
		// Restore activeLandscapeConstraints from already tested valid contraints or initial one if valid one does not exist.
		self.activeLandscapeConstraints = self.activeLandscapeConstraints ?: self.initialLandscapeConstraints;
		[NSLayoutConstraint deactivateConstraints:self.activePortraitConstraints];
		[NSLayoutConstraint activateConstraints:self.activeLandscapeConstraints];
	} else {
		// Restore activePortraitConstraints from already tested valid contraints or initial one if valid one does not exist.
		self.activePortraitConstraints = self.activePortraitConstraints ?: self.initialPortraitConstraints;
		[NSLayoutConstraint deactivateConstraints:self.activeLandscapeConstraints];
		[NSLayoutConstraint activateConstraints:self.activePortraitConstraints];
	}
	[self setNeedsLayout];
	[self layoutIfNeeded];
}

/**
 *	@brief setup subviews if scrollview is not set up in initial stage.
 */
- (void)setupSubviewsIfNeeded {
	[self setupSubViews];
	self.hasSetConstraints = NO;
	[self setNeedsUpdateConstraints];
	self.selectedIndex = -1;
}

- (void)clearSubviews {
	for (UIView *view in self.subviews) {
		[view removeFromSuperview];
	}
	self.titleButtons = nil;
	self.selectedIndex = -1;
}

#pragma mark - Selection Control

- (void)setSelectedIndex:(int)selectedIndex {
	_selectedIndex = selectedIndex;
	
	[self.titleButtons enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		UIButton *button = (UIButton *)obj;
		button.selected = NO;
	}];
	
	if ([self validSelectedIndex:selectedIndex]) {
		UIButton *selectedButton = [self.titleButtons objectAtIndex:selectedIndex];
		selectedButton.selected = YES;
		[self scrollToCell:selectedButton];
	}
}

- (void)tapped:(id)sender {
	UIButton *tappedButton = (UIButton *)sender;
	__block int tappedIndex;
	[self.titleButtons enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if (obj == tappedButton) {
			tappedIndex = (int)idx;
			*stop = YES;
		}
	}];
	
	[self.tapDelegate horizontalSelectableView:self selectIndex:tappedIndex];
	if (tappedIndex != self.selectedIndex) {
		[self advanceSelectedIndexBy:tappedIndex - self.selectedIndex];
	}
}

- (void)advanceToNext {
	[self advanceSelectedIndexBy:1];
}

- (void)fallbackToPrevious {
	[self advanceSelectedIndexBy:-1];
}

#pragma mark - Private Helpers

- (BOOL)validSelectedIndex:(int)selectedIndex {
	return selectedIndex >=0 && selectedIndex < self.titles.count;
}

/**
 *	@brief advanceSelectedIndexBy
 *	@param step pos number means advance by step, nag number means fallback by step.
 */
- (void)advanceSelectedIndexBy:(int)step {
	int itemsCount = (int)self.titleButtons.count;
	int nextIndex = self.selectedIndex;
	nextIndex += step;
	if (nextIndex < 0 || nextIndex >= itemsCount) {
		// we've reached the border already
		return;
	}
	
	self.selectedIndex = nextIndex;
	UIButton *toShowButton = (UIButton *)[self.titleButtons objectAtIndex:self.selectedIndex];
	
	[self scrollToCell:toShowButton];
}

- (void)scrollToCell:(UIButton *)toShowCell {
	// when left scroll, if selectedIndex is less than the last element of our visible index, we do nothing.
	NSIndexPath *toShowIndexPath = [NSIndexPath indexPathForRow:self.selectedIndex inSection:0];
	NSArray *visibleIndexPaths = [self indexesForVisibleItems];
	
	
	__block int greaterOrEqualIndexesCount = 0;
	__block int lessOrEqualIndexesCount = 0;
	[visibleIndexPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		NSIndexPath *currentIndexPath = (NSIndexPath *)obj;
		if (currentIndexPath.section == toShowIndexPath.section && toShowIndexPath.row >= currentIndexPath.row) {
			greaterOrEqualIndexesCount++;
		}
		
		if (currentIndexPath.section == toShowIndexPath.section && toShowIndexPath.row <= currentIndexPath.row) {
			lessOrEqualIndexesCount++;
		}
	}];
	
	if (greaterOrEqualIndexesCount >= visibleIndexPaths.count) {
		// left scroll
		// Now we should adjust contentoffset to show toShowCell.
		CGFloat screenWidth = self.frame.size.width;
		CGRect toShowCellFrame = toShowCell.frame;
		
		[self setContentOffset:CGPointMake(CGRectGetMaxX(toShowCellFrame) +  kHorizontalItemSpace/2 - screenWidth, 0) animated:YES];
	}
	
	if (lessOrEqualIndexesCount >= visibleIndexPaths.count) {
		// right scroll
		// Now we should adjust contentoffset to show toShowCell.
		CGRect toShowCellFrame = toShowCell.frame;
		
		[self setContentOffset:CGPointMake(CGRectGetMinX(toShowCellFrame) - kHorizontalItemSpace/2, 0) animated:YES];
	}
}

- (NSArray *)indexesForVisibleItems {
	// Here we rely on layout information, so manually trigger layout pass.
	[self setNeedsLayout];
	[self layoutIfNeeded];
	
	NSMutableArray *visibleItems = [[NSMutableArray alloc] initWithCapacity:self.titleButtons.count];
	CGFloat screenWidth = self.frame.size.width;
	
	CGFloat visibleAreaStartX = self.contentOffset.x;
	CGFloat visibleAreaEndX = self.contentOffset.x + screenWidth;
	
	[self.titleButtons enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		CGRect currentFrame = obj.frame;
		
		CGFloat testStartX = CGRectGetMinX(currentFrame);
		CGFloat testEndX = CGRectGetMaxX(currentFrame);
		
		if ((testEndX > visibleAreaStartX && testEndX < visibleAreaEndX) || (testStartX > visibleAreaStartX && testStartX < visibleAreaEndX)){
			[visibleItems addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
		}
	}];
	return [visibleItems copy];
}

- (CreateButtonBlock)defaultCreateButtonBlock {
	CreateButtonBlock defaultCreateButtonBlock = ^{
		UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
		button.titleLabel.font = [UIFont systemFontOfSize:18.0f];
		button.translatesAutoresizingMaskIntoConstraints = false;
		
		[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[button setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
		return button;
	};
	return defaultCreateButtonBlock;
}

@end
