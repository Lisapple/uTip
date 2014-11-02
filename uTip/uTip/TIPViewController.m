//
//  TIPViewController.m
//  uTip
//
//  Created by Maxime on 10/18/14.
//  Copyright (c) 2014 Lis@cintosh. All rights reserved.
//

#import "TIPViewController.h"
#import "TIPPawnView.h"

typedef NS_ENUM(NSUInteger, TIPSelectedField) {
	TIPSelectedFieldNone,
	TIPSelectedFieldAmount = 1,
	TIPSelectedFieldPercent,
	TIPSelectedFieldShare,
	TIPSelectedFieldTotal
};

typedef NS_ENUM(NSUInteger, TIPTotalDisplayType) {
	TIPTotalDisplayTypeDetails	= 1 << 0, // "amount * percent / share \n"
	TIPTotalDisplayTypeTip		= 1 << 1, // "amount + tip \n"
	TIPTotalDisplayTypeTotal	= 1 << 2, // "total"
	
	TIPTotalDisplayTypeDefault	= (TIPTotalDisplayTypeTip | TIPTotalDisplayTypeTotal),
	TIPTotalDisplayTypeDetailsTotal = (TIPTotalDisplayTypeDetails | TIPTotalDisplayTypeTotal),
	TIPTotalDisplayTypeFull = (TIPTotalDisplayTypeDetails | TIPTotalDisplayTypeTip | TIPTotalDisplayTypeTotal),
};

@interface TIPViewController ()
{
	CGFloat amount, percent, share;
}

@property (nonatomic, assign) TIPSelectedField selectedField;
@property (nonatomic, assign) TIPTotalDisplayType displayType;

@property (nonatomic, strong) NSArray * pawnsView, * pawnsMaskView;
@property (nonatomic, weak) UIView *selectedPawnView, *selectedPawnMaskView;
@property (nonatomic, assign) CGPoint startPosition, position;
@property (nonatomic, assign) float value;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) IBOutlet UIView * statusBarView;
@property (nonatomic, assign) IBOutlet UILabel * tutorialLabel;
@property (nonatomic, assign) IBOutlet UILabel * amountLabel, * percentLabel, * shareLabel;
@property (nonatomic, assign) IBOutlet UILabel * amountMaskLabel, * percentMaskLabel, * shareMaskLabel;
@property (nonatomic, assign) IBOutlet UILabel * totalLabel;
@property (nonatomic, assign) IBOutlet UILabel * totalMaskLabel;

@property (nonatomic, assign) IBOutlet UIView * pinView;

@end

@implementation TIPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	/*
	 NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	 if (![defaults boolForKey:@"tutorial-shown"]) {
	 // @TODO: Display |statusBarView| and |tutorialLabel|
	 // @TODO: Show tutorial
	 [defaults setBool:YES forKey:@"tutorial-shown"];
	 }
	 */
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:@"amount"]) {
		amount = [defaults integerForKey:@"amount"];
		percent = [defaults integerForKey:@"percent"];
		share = [defaults integerForKey:@"share"];
	} else {
		amount = 120.;
		percent = 15;
		share = 4;
	}
	
	
	NSArray * textColors = @[ [UIColor orangeColor],
							  [UIColor colorWithRed:0. green:0.5 blue:0.5 alpha:1.],
							  [UIColor colorWithRed:0.5 green:0. blue:0.5 alpha:1.] ];
	NSArray * labels = @[ self.amountLabel, self.percentLabel, self.shareLabel ];
	NSInteger index = 0;
	for (UILabel *label in labels) {
		label.textColor = textColors[index++];
	}
	
	self.displayType = TIPTotalDisplayTypeDefault;
	[self updateLabels];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
													  object:nil
													   queue:[NSOperationQueue currentQueue]
												  usingBlock:^(NSNotification *note) {
													  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
													  [defaults setInteger:amount forKey:@"amount"];
													  [defaults setInteger:percent forKey:@"percent"];
													  [defaults setInteger:share forKey:@"share"];
													  [defaults synchronize]; }];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	NSMutableArray * mPawnsView = [[NSMutableArray alloc] initWithCapacity:4];
	NSMutableArray * mPawnsMaskView = [[NSMutableArray alloc] initWithCapacity:4];
	
	NSArray * labels = @[ self.amountLabel, self.percentLabel, self.shareLabel ];
	NSArray * maskLabels = @[ self.amountMaskLabel, self.percentMaskLabel, self.shareMaskLabel ];
	NSArray * colors = @[ @[ [UIColor redColor], [UIColor yellowColor] ],
						  @[ [UIColor greenColor], [UIColor blueColor] ],
						  @[ [UIColor purpleColor], [UIColor redColor] ] ];
	NSInteger index = 0;
	for (UILabel *label in labels) {
		
		CGRect frame = CGRectMake(self.view.center.x, label.center.y - 30., 60., 60.);
		TIPPawnView * pawnView = [[TIPPawnView alloc] initWithFrame:frame];
		pawnView.layer.cornerRadius = 30.;
		pawnView.colors = colors[index];
		[self.view addSubview:pawnView];
		pawnView.transform = CGAffineTransformMakeScale(0., 0.);
		[mPawnsView addObject:pawnView];
		
		frame = CGRectMake(-100., 0., 60., 60.);
		UIView * pawnMaskView = [[UIView alloc] initWithFrame:frame];
		pawnMaskView.layer.cornerRadius = 30.;
		pawnMaskView.backgroundColor = [UIColor blackColor];
		[self.view addSubview:pawnMaskView];
		pawnMaskView.transform = CGAffineTransformMakeScale(0., 0.);
		[mPawnsMaskView addObject:pawnMaskView];
		
		UILabel * maskLabel = maskLabels[index];
		[self.view bringSubviewToFront:maskLabel];
		maskLabel.layer.mask = pawnMaskView.layer;
		
		++index;
	}
	
	{
		CGRect frame = CGRectMake(self.view.center.x, self.totalLabel.center.y - 30., 60., 60.);
		UIView * pawnView = [[UIView alloc] initWithFrame:frame];
		pawnView.layer.cornerRadius = 30.;
		pawnView.backgroundColor = [UIColor whiteColor];
		[self.view addSubview:pawnView];
		pawnView.transform = CGAffineTransformMakeScale(0., 0.);
		[mPawnsView addObject:pawnView];
		
		frame = CGRectMake(-100., 0., 60., 60.);
		UIView * pawnMaskView = [[UIView alloc] initWithFrame:frame];
		pawnMaskView.layer.cornerRadius = 30.;
		pawnMaskView.backgroundColor = [UIColor blackColor];
		[self.view addSubview:pawnMaskView];
		pawnMaskView.transform = CGAffineTransformMakeScale(0., 0.);
		[mPawnsMaskView addObject:pawnMaskView];
		
		self.totalMaskLabel.layer.mask = pawnMaskView.layer;
		[self.view bringSubviewToFront:self.totalMaskLabel];
		/*
		 self.totalMaskLabel = [[UILabel alloc] initWithFrame:self.totalLabel.frame];
		 self.totalMaskLabel.textColor = [UIColor blackColor];
		 [self.totalMaskLabel addConstraints:self.totalLabel.constraints];
		 self.totalMaskLabel.font = self.totalLabel.font;
		 self.totalMaskLabel.text = self.totalLabel.text;
		 self.totalMaskLabel.numberOfLines = 0;
		 self.totalMaskLabel.adjustsFontSizeToFitWidth = YES;
		 self.totalMaskLabel.minimumScaleFactor = self.totalLabel.minimumScaleFactor;
		 self.totalMaskLabel.tag = self.totalLabel.tag = 101;
		 self.totalMaskLabel.layer.mask = pawnMaskView.layer;
		 [self.view addSubview:self.totalMaskLabel];
		 */
	}
	
	self.pawnsView = mPawnsView;
	self.pawnsMaskView = mPawnsMaskView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (IBAction)changeTotalDisplayAction:(id)sender
{
	switch (self.displayType) {
		case TIPTotalDisplayTypeDetailsTotal:
			self.displayType = TIPTotalDisplayTypeFull; break;
		case TIPTotalDisplayTypeFull:
			self.displayType = TIPTotalDisplayTypeTotal; break;
		case TIPTotalDisplayTypeDefault:
			self.displayType = TIPTotalDisplayTypeDetailsTotal; break;
		default:
			self.displayType = TIPTotalDisplayTypeDefault; break;
	}
	[self updateLabels];
}

#pragma mark - Update

- (void)updateLabels
{
	/*
	 self.amountLabel.enabled = self.percentLabel.enabled = self.shareLabel.enabled = YES;
	 switch (self.selectedField) {
	 case TIPSelectedFieldAmount: {
	 self.percentLabel.enabled = self.shareLabel.enabled = NO;
	 }
	 break;
	 case TIPSelectedFieldPercent: {
	 self.amountLabel.enabled = self.shareLabel.enabled = NO;
	 }
	 break;
	 case TIPSelectedFieldShare: {
	 self.amountLabel.enabled = self.percentLabel.enabled = NO;
	 }
	 break;
	 case TIPSelectedFieldTotal: {
	 self.amountLabel.enabled = self.percentLabel.enabled = self.shareLabel.enabled = NO;
	 }
	 default: break;
	 }
	 */
	self.amountLabel.enabled = (self.selectedField == TIPSelectedFieldAmount);
	self.percentLabel.enabled = (self.selectedField == TIPSelectedFieldPercent);
	self.shareLabel.enabled = (self.selectedField == TIPSelectedFieldShare);
	
	if (self.selectedField == TIPSelectedFieldNone)
		self.amountLabel.enabled = self.percentLabel.enabled = self.shareLabel.enabled = YES;
	
	NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
	formatter.locale = [NSLocale currentLocale];
	formatter.numberStyle = NSNumberFormatterCurrencyStyle;
	self.amountMaskLabel.text = self.amountLabel.text = [formatter stringFromNumber:@(amount)];
	
	NSNumberFormatter * percentFormatter = [[NSNumberFormatter alloc] init];
	percentFormatter.numberStyle = NSNumberFormatterDecimalStyle;
	percentFormatter.minimumFractionDigits = 0;
	percentFormatter.maximumFractionDigits = 1;
	self.percentMaskLabel.text = self.percentLabel.text = [NSString stringWithFormat:@"%@%%", [percentFormatter stringFromNumber:@(percent)]];
	
	self.shareMaskLabel.text = self.shareLabel.text = [NSString stringWithFormat:@"/%ld", (long)share];
	
	NSMutableString * string = [[NSMutableString alloc] initWithCapacity:50];
	if (self.displayType & TIPTotalDisplayTypeDetails) {
		[string appendFormat:@"= %@ * %0.1f%% / %ld\n", [formatter stringFromNumber:@(amount)], percent, (long)share];
	}
	if (self.displayType & TIPTotalDisplayTypeTip) {
		[string appendFormat:@"= %@ + %@\n", [formatter stringFromNumber:@(amount)],
		 [formatter stringFromNumber:@(amount * percent / 100. / (float)(long)share)]];
	}
	if (self.displayType & TIPTotalDisplayTypeTotal) {
		[string appendFormat:@"= %@",
		 [formatter stringFromNumber:@(amount + amount * percent / 100. / (float)(long)share)]];
	}
	self.totalMaskLabel.text = self.totalLabel.text = string;
}

#pragma mark - Timers

- (void)incrementValue:(NSTimer *)timer
{
	CGFloat scale = 0.25 + MAX(0., 2. * ((self.view.frame.size.height - 50.) - self.position.y) / self.view.frame.size.height);
	switch (self.selectedField) {
		case TIPSelectedFieldAmount:
			amount += scale * 10.;
			amount = MIN(MAX(0, amount), 42e6); break;
		case TIPSelectedFieldPercent:
		case TIPSelectedFieldTotal:
			percent += scale * 2;
			percent = MIN(MAX(0, percent), 100); break;
		case TIPSelectedFieldShare:
			share += scale * 0.5;
			share = MIN(MAX(1, share), 42);
		default: break;
	}
	[self updateLabels];
}

- (void)decrementValue:(NSTimer *)timer
{
	CGFloat scale = 0.25 + MAX(0., 2. * ((self.view.frame.size.height - 50.) - self.position.y) / self.view.frame.size.height);
	switch (self.selectedField) {
		case TIPSelectedFieldAmount:
			amount -= scale * 10.;
			amount = MIN(MAX(0, amount), 42e6); break;
		case TIPSelectedFieldPercent:
		case TIPSelectedFieldTotal:
			percent -= scale * 2;
			percent = MIN(MAX(0, percent), 100); break;
		case TIPSelectedFieldShare:
			share -= scale * 0.5;
			share = MIN(MAX(1, share), 42);
		default: break;
	}
	[self updateLabels];
}

#pragma mark - Touches management

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch * touch = touches.anyObject;
	CGPoint location = [touch locationInView:self.view];
	if (touch.view == _pinView) {
		self.startPosition = location;
		
	} else {
		if /**/ (0. < location.y &&
				 location.y <= self.amountLabel.frame.origin.y + self.amountLabel.frame.size.height + 10.) {
			self.selectedField = TIPSelectedFieldAmount;
		}
		else if (self.amountLabel.frame.origin.y + self.amountLabel.frame.size.height + 10. < location.y &&
				 location.y <= self.percentLabel.frame.origin.y + self.percentLabel.frame.size.height + 10.) {
			self.selectedField = TIPSelectedFieldPercent;
		}
		else if (self.percentLabel.frame.origin.y + self.percentLabel.frame.size.height + 10. < location.y &&
				 location.y <= self.shareLabel.frame.origin.y + self.shareLabel.frame.size.height + 10.) {
			self.selectedField = TIPSelectedFieldShare;
		}
		else {
			self.selectedField = TIPSelectedFieldTotal;
		}
		
		NSInteger index = (self.selectedField - TIPSelectedFieldAmount);
		self.selectedPawnView = self.pawnsView[index];
		self.selectedPawnMaskView = self.pawnsMaskView[index];
		
		UILabel * label = (UILabel *)self.selectedPawnMaskView.layer.superlayer.delegate;
		self.selectedPawnMaskView.center = CGPointMake(self.selectedPawnView.center.x - label.frame.origin.x,
													   ceilf(label.frame.size.height / 2.));
		
		self.selectedPawnView.transform = CGAffineTransformMakeScale(0., 0.);
		self.selectedPawnMaskView.transform = CGAffineTransformMakeScale(0., 0.);
		[UIView animateWithDuration:0.333
							  delay:0.
			 usingSpringWithDamping:0.5
			  initialSpringVelocity:0.
							options:0
						 animations:^{
							 CGFloat scale = 0.25 + MAX(0., 2. * ((self.view.frame.size.height - 50.) - location.y) / self.view.frame.size.height);
							 self.selectedPawnView.transform = CGAffineTransformMakeScale(scale, scale);
							 self.selectedPawnMaskView.transform = CGAffineTransformMakeScale(scale, scale); }
						 completion:NULL];
		
		[self updateLabels];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch * touch = touches.anyObject;
	self.position = [touch locationInView:self.view.window];
	if (touch.view == _pinView) {
		
		/*
		CGRect frame = self.view.frame;
		frame.origin.y = -MAX(0., MIN(self.startPosition.y - self.position.y, self.view.frame.size.height * 0.6));
		self.view.frame = frame;
		*/
		/*
		CGFloat y = MAX(0., MIN((self.startPosition.y - self.position.y), [UIScreen mainScreen].bounds.size.height * 0.6));
		CATransform3D transform = Transform3DMakePerspectiveRotation(MIN(0.1 * y / 100., M_PI_4), 1., 0., 0.);
		self.view.layer.transform = CATransform3DTranslate(transform, 0., -y, 0.);
		 */
		
	} else {
		CGFloat scale = 0.25 + MAX(0., 2. * ((self.view.frame.size.height - 50.) - self.position.y) / self.view.frame.size.height);
		self.selectedPawnMaskView.transform = CGAffineTransformMakeScale(scale, scale);
		self.selectedPawnView.transform = CGAffineTransformMakeScale(scale, scale);
		
		if (40. * scale < self.position.x &&
			self.position.x < (self.view.frame.size.width - 40. * scale)) {
			[self.timer invalidate];
			
			CGPoint prevPosition = [((UITouch *)touches.anyObject) previousLocationInView:self.view];
			CGFloat delta = (self.position.x - prevPosition.x);
			CGFloat x = (self.selectedPawnView.center.x + delta * scale);
			x = MIN(MAX(30., x), (self.view.frame.size.width - 30.));
			self.selectedPawnView.center = CGPointMake(x, self.selectedPawnView.center.y);
			
			UILabel * label = (UILabel *)self.selectedPawnMaskView.layer.superlayer.delegate;
			self.selectedPawnMaskView.center = CGPointMake(self.selectedPawnView.center.x - label.frame.origin.x,
														   ceilf(label.frame.size.height / 2.));
			switch (self.selectedField) {
				case TIPSelectedFieldAmount: {
					float d = 0.;
					if /**/ (ABS(scale) > 1.2)
						d = (delta > 0) ? 1. : -1.;
					else if (ABS(scale) > 0.8)
						d = ((delta > 0) ? 0.2 : -0.2) / 5.;
					else if (ABS(scale) > 0.4)
						d = ((delta > 0) ? 0.05 : -0.05) / 10.;
					else
						d = ((delta > 0) ? 0.01 : -0.01) / 10.;
					
					amount += d;
					amount = MIN(MAX(0, amount), 42e6);
				}
					break;
				case TIPSelectedFieldPercent:
				case TIPSelectedFieldTotal:
					percent += delta * scale * 0.25;
					percent = MIN(MAX(0, percent), 100); break;
				case TIPSelectedFieldShare:
					share += delta * scale / 20;
					share = MIN(MAX(1, share), 42);
				default: break;
			}
			[self updateLabels];
		} else if (self.position.x <= 40. * scale) {
			[self.timer invalidate];
			self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05
														  target:self
														selector:@selector(decrementValue:)
														userInfo:nil
														 repeats:YES];
		} else if ((self.view.frame.size.width - 40. * scale) <= self.position.x)  {
			[self.timer invalidate];
			self.timer = [NSTimer scheduledTimerWithTimeInterval:0.05
														  target:self
														selector:@selector(incrementValue:)
														userInfo:nil
														 repeats:YES];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[UIView animateWithDuration:0.15
					 animations:^{
						 self.selectedPawnMaskView.transform = CGAffineTransformMakeScale(0., 0.);
						 self.selectedPawnView.transform = CGAffineTransformMakeScale(0., 0.); }];
	
	[self.timer invalidate];
	
	self.selectedField = TIPSelectedFieldNone;
	[self updateLabels];
}

@end
