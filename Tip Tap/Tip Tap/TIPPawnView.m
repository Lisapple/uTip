//
//  TIPPawnView.m
//  Tip Tap
//
//  Created by Maxime on 10/21/14.
//  Copyright (c) 2014 Lis@cintosh. All rights reserved.
//

#import "TIPPawnView.h"

@implementation TIPPawnView

/*
 + (Class)layerClass
 {
 return [CAGradientLayer class];
 }
 */

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		/*
		 CAGradientLayer * layer = (CAGradientLayer *)self.layer;
		 layer.colors = @[ [UIColor blueColor], [UIColor redColor] ];
		 layer.locations = @[ @0., @1. ];
		 layer.startPoint = frame.origin;//CGPointMake(0., 0.);
		 layer.endPoint = CGPointMake(frame.origin.x + frame.size.width,
		 frame.origin.y + frame.size.height);//CGPointMake(frame.size.width, frame.size.height);
		 */
		
		self.layer.allowsEdgeAntialiasing = YES;
		//self.layer.shouldRasterize = YES;
		//self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }
    return self;
}

- (BOOL)isOpaque
{
	return NO;
}

- (void)setColors:(NSArray *)colors
{
	_colors = colors;
	
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	if (_colors.count == 2) {
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		CGContextBeginPath(context);
		CGContextAddEllipseInRect(context, rect);
		CGContextClip(context);
		
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		NSArray *gradientColors = @[ (id)[_colors[0] CGColor], (id)[_colors[1] CGColor] ];
		CGFloat gradientLocations[] = {0., 1.};
		CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
		CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(rect.origin.x + rect.size.width,
																				rect.origin.y + rect.size.height), 0);
	}
}

@end
